function commander(c::Client, m::Message, ::Val{:source})
	startswith(m.content, COMMAND_PREFIX * "src") || return
		
	regex = Regex(COMMAND_PREFIX * raw"src( help| discourse| gm| ig| j| react| src| tz)? *(.*)$")

	matches = match(regex, m.content)

	if matches === nothing || matches.captures[1] ∈ (" help", nothing)
		help_commander(c, m, :source)
	elseif lowercase(strip(matches.captures[1])) ∈ ("discourse", "gm", "ig", "j", "react", "src", "tz")
		msg = string(BOT_REPO_URL, "/blob/main/src/command/", lowercase(strip(matches.captures[1])), ".jl")
		reply(c, m, msg)
	else
		reply(c, m, "No such blob or file. Please check out $(BOT_REPO_URL) instead")
	end
	return nothing
end

# I wonder if it is possible to only have one file for this help_commander function so that we won't repeat ourselves
function help_commander(c::Client, m::Message, ::Val{:source})
	reply(c, m, """
		  How to use `src` command:
		  ```
		  src help
		  src react
		  src <command>
		  ```
		  Check out the $(BOT_REPO_URL) to see the code and commands.
		  """
		  )
end

