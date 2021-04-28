# Main constants
const BOT_REPO_URL = "https://github.com/Humans-of-Julia/HoJBot.jl"

const active_commands = LittleDict([
    :gm => false,
    :ig => true,
    :j => true,
    :react => true,
    :tz => true,
    :discourse => true,
    :src => true,
])

const commands_names = LittleDict([
    :gm => :game_master,
    :ig => :ig,
    :j => :julia_doc,
    :react => :reaction,
    :tz => :time_zone,
    :discourse => :discourse,
    :src => :source,
])

const handlers_list = [
    (:reaction, MessageCreate, true),
    (:whistle, MessageReactionAdd, true),
    (:discourse, MessageReactionAdd, true),
]

const opt_services_list = [:game_master, :reaction]

# RAW Regex constants
const RAW_REGEX_SRC_CMD = raw"src( help| discourse| gm| ig| j| react| src| tz)? *(.*)$"
