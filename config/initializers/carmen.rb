# frozen_string_literal: true

# Carmen country/region library is required for address handling
# In parent apps, ensure carmen gem is loaded
if defined?(Carmen)
  Carmen.i18n_backend.locale = :ja
end
