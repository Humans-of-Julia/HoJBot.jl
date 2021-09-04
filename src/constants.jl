# Main constants
const BOT_REPO_URL = "https://github.com/Humans-of-Julia/HoJBot.jl"

const ACTIVE_COMMANDS = LittleDict([
    :gm => false,
    :ig => true,
    :j => true,
    :react => true,
    :tz => true,
    :discourse => true,
    :src => true,
    :jc => true,
])

const COMMANDS_NAMES = LittleDict([
    :gm => :game_master,
    :ig => :ig,
    :j => :julia_doc,
    :react => :reaction,
    :tz => :time_zone,
    :discourse => :discourse,
    :src => :source,
    :jc => :julia_con,
])

const HANDLERS_LIST = [
    (:discourse, MessageReactionAdd, true),
    (:mod, MessageCreate, true),
    (:mod, MessageUpdate, true),
    (:reaction, MessageCreate, true),
    (:whistle, MessageReactionAdd, true),
]

const OPT_SERVICES_LIST = [:game_master, :reaction]

const FAKENOW = Dates.DateTime("2020-07-29T16:30:00.000")
