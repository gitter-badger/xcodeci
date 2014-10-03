class Logger
  def ok
    "✔︎".green
  end
  def ko
    "✘".red
  end

  def log_result(status, description)
    status ? "  [ #{ok} ] #{description}" : "  [ #{ko} ] #{description}"
  end
end
