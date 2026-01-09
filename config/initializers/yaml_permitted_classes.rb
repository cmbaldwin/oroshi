# frozen_string_literal: true

# Configure permitted classes for YAML deserialization
# This is required for models that use `serialize :field, coder: YAML`
# and store objects like Date, Time, Symbol, etc.
#
# Security Note: These classes are safe to deserialize as they don't
# allow arbitrary code execution. However, migrating to JSON serialization
# is recommended (see CVE-2022-32224).

ActiveRecord.yaml_column_permitted_classes = [
  Symbol,
  Date,
  Time,
  ActiveSupport::TimeWithZone,
  ActiveSupport::HashWithIndifferentAccess
]
