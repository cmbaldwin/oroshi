class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Oroshi engine provides authentication via Devise
  before_action :authenticate_user!

  private

  def check_vip
    unless current_user&.vip? || current_user&.admin?
      redirect_to root_path, alert: "VIP以上の権限が必要です。"
    end
  end

  def check_admin
    unless current_user&.admin?
      redirect_to root_path, alert: "管理者権限が必要です。"
    end
  end
end
