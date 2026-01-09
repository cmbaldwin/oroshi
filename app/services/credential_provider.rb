# frozen_string_literal: true

class CredentialProvider
  class << self
    # Get credential value (with fallback to ENV for backward compatibility)
    # @param service [String, Symbol] The service name (e.g., 'sendgrid', 'gcs')
    # @param key_name [String, Symbol] The credential key name (e.g., 'api_key', 'project')
    # @param user [User, nil] Optional user for user-specific credentials
    # @return [String, nil] The credential value or nil if not found
    def get(service, key_name, user: nil)
      credential = Credential.active
                             .where(service: service.to_s, key_name: key_name.to_s)
                             .where(user_id: user&.id)
                             .order(created_at: :desc)
                             .first

      # Return database value if found, otherwise fallback to ENV
      credential&.value || env_fallback(service, key_name)
    end

    # Get all credentials for a service as a hash
    # @param service [String, Symbol] The service name
    # @param user [User, nil] Optional user for user-specific credentials
    # @return [Hash] Hash of key_name => value pairs
    def for_service(service, user: nil)
      Credential.active
                .where(service: service.to_s)
                .where(user_id: user&.id)
                .each_with_object({}) do |cred, hash|
                  hash[cred.key_name.to_sym] = cred.value
      end
    end

    # Check if a service is fully configured
    # @param service [String, Symbol] The service name
    # @return [Boolean] True if service is enabled and has all required credentials
    def configured?(service)
      service_config = ServiceConfiguration.find_by(service: service.to_s)
      return false unless service_config&.enabled?

      service_config.fully_configured?
    end

    # Get configuration status for a service
    # @param service [String, Symbol] The service name
    # @return [Hash] Configuration status details
    def status(service)
      service_config = ServiceConfiguration.find_by(service: service.to_s)

      unless service_config
        return {
          configured: false,
          enabled: false,
          missing_credentials: [],
          error: 'Service not found'
        }
      end

      required = service_config.required_credentials
      existing = Credential.active.where(service: service.to_s).pluck(:key_name)
      missing = required - existing

      {
        configured: missing.empty? && service_config.enabled?,
        enabled: service_config.enabled?,
        required_credentials: required,
        existing_credentials: existing,
        missing_credentials: missing
      }
    end

    private

    # Fallback to environment variables for backward compatibility
    # Maps service + key_name to legacy ENV variable names
    def env_fallback(service, key_name)
      mapping = env_variable_mapping(service.to_s, key_name.to_s)
      ENV[mapping] if mapping
    end

    # Map service/key combinations to legacy ENV variable names
    def env_variable_mapping(service, key_name)
      case service
      when 'google_cloud_storage', 'gcs'
        case key_name
        when 'project' then 'GCLOUD_PROJECT'
        when 'bucket' then 'GCLOUD_BUCKET'
        when 'credentials_path' then 'GCLOUD_CREDENTIALS_PATH'
        when 'bucket_prefix' then 'GBUCKET_PREFIX'
        end
      when 'sendgrid'
        case key_name
        when 'api_username' then 'SENDGRID_TWILIO_API_USERNAME'
        when 'api_password' then 'SENDGRID_TWILIO_API_PASSWORD'
        when 'mail_sender' then 'MAIL_SENDER'
        end
      when 'rakuten'
        case key_name
        when 'api_key' then 'RAKUTEN_API'
        when 'service_secret' then 'RAKUTEN_SERVICE_SECRET'
        when 'license_key' then 'RAKUTEN_LICENSE_KEY'
        end
      when 'yahoo_v2'
        case key_name
        when 'client_id' then 'YAHOO_CLIENT_V2'
        when 'client_secret' then 'YAHOO_SECRET_V2'
        when 'seller_id' then 'YAHOO_SELLER_ID'
        end
      when 'yahoo_v1'
        case key_name
        when 'secret' then 'YAHOO_SECRET'
        when 'client_id' then 'YAHOO_CLIENT_ID'
        when 'pem_file' then 'YAHOO_PEM_FILE'
        when 'pem_pass' then 'YAHOO_PEM_PASS'
        end
      when 'infomart'
        case key_name
        when 'login' then 'INFOMART_LOGIN'
        when 'password' then 'INFOMART_PASS'
        end
      end
    end
  end
end
