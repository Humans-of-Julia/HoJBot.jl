export role_id
function role_id(role::AbstractString)
    if role[1]=='<' && role[2]=='@' && role[3]=='&' && role[end]=='>'
        role = role[4:end-1]
    end
    return tryparse(Discord.Snowflake, role)
end
