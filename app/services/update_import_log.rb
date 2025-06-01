class UpdateImportLog
  def initialize
    @log = ImportLog.new
  end

  def update_log(message, debug)
    if debug
      status = "error"
    else
      status = "success"
    end
    record = ApiUpdateLog.new(result: message, status: status)
    unless record.save
      # write it to the log
      @log.api_logger.debug "api_update_log, error: Could not save: record.errors.full_messages"
    end
  end
end
