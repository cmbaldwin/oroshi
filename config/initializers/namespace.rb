# frozen_string_literal: true

# Load Oroshi module - check if in engine test mode or regular app mode
oroshi_module_path = Rails.root.join("app", "models", "oroshi")
require oroshi_module_path if oroshi_module_path.exist?
