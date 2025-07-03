module Error
  class CustomError < StandardError
    attr_reader :status, :details

    def initialize(status = :bad_request, message = nil, details: nil)
      @status  = status
      @details = details
      super(message || "Something went wrong")
    end
  end
end
