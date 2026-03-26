# frozen_string_literal: true

class HttpUrlValidator < ActiveModel::EachValidator
  HTTP_URL_PATTERN = URI::DEFAULT_PARSER.make_regexp(%w[http https])

  # 検証のタイミングでRailsがvalidate_eachを実行する
  def validate_each(record, attribute, value)
    # urlが空なら検証しない
    return if value.blank?

    unless HTTP_URL_PATTERN.match?(value)
      record.errors.add(attribute, :invalid_url)
    end
  end
end
