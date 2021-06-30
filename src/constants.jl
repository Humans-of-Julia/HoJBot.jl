# Main constants
const BOT_REPO_URL = "https://github.com/Humans-of-Julia/HoJBot.jl"

const ACTIVE_COMMANDS = LittleDict([
    :gm => false,
    :ig => false,
    :j => false,
    :q => true,
    :react => false,
    :tz => false,
    :discourse => false,
    :src => false,
])

const COMMANDS_NAMES = LittleDict([
    :gm => :game_master,
    :ig => :ig,
    :j => :julia_doc,
    :q => :queue,
    :react => :reaction,
    :tz => :time_zone,
    :discourse => :discourse,
    :src => :source,
])

const HANDLERS_LIST = [
    (:discourse, MessageReactionAdd, true),
    (:mod,       MessageCreate,      true),
    (:mod,       MessageUpdate,      true),
    (:reaction,  MessageCreate,      true),
    (:whistle,   MessageReactionAdd, true),
]

const OPT_SERVICES_LIST = [:game_master, :reaction]
