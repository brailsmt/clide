
class Plugin
  ##
  # Display help message
  def help
      raise "Plugin.help() Not implemented!"
  end

  ##
  # Do stuff when this plugin is invoked
  def run(args = nil)
      raise "Plugin.run() Not implemented!"
  end

  ##
  # The name of the command
  def name
      raise "Plugin.name() Not implemented!"
  end

  ##
  # Aliases to the plugin itself
  def name_aliases
      raise "Plugin.name_aliases Not implemented"
  end

  ##
  # List of all commands that this Plugin responds to
  def commands
      raise "Plugin.commands() Not implemented!"
  end

  ##
  # A hash of aliases to commands
  def command_aliases
      raise "Plugin.commands() Not implemented!"
  end
end
