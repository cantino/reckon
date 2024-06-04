module Reckon
  LOGGER = Logger.new(STDERR)
  LOGGER.level = Logger::WARN

  def log(tag, msg)
    LOGGER.add(Logger::WARN, msg, tag)
  end
end
