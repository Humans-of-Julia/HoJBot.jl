"""
    _github_profile_command(c::Client, m::Message, query)

Searches github profile using https://api.github.com/ and returns it as a discord embed

"""
function _github_profile_command(c::Client, m::Message, query::SubString{String})
    # I used try catch here because it errors instead of storing the json if status is 404.
    # You can test it on your side btw to confirm error
    # Maybe I missed something.
    try
        response = HTTP.get(string(GH_API_URL, "users/$(query)"))
        if response.status == 200
            json_data = JSON3.read(response.body)
            avatar = Discord.EmbedThumbnail(;
                url=json_data[:avatar_url], height=24, width=24
            )
            bio = isnothing(json_data[:bio]) ? "No information" : json_data[:bio]
            followers = json_data[:followers]
            following = json_data[:following]
            github_profile_url = json_data[:html_url]
            public_repos = json_data[:public_repos]
            username = json_data[:login]
            org_response = HTTP.get(json_data[:organizations_url])
            org_body_stringify = String(org_response.body)
            org_json_body = JSON3.read(org_body_stringify)
            org_data = _github_organization_data(org_json_body)
            date_created = json_data[:created_at]
            convert_datetime = ZonedDateTime(date_created, "yyyy-mm-ddTHH:MM:SSz")
            formatted_datetime = string(Date(convert_datetime), UTC)
            footer = Discord.EmbedFooter(; text="Account created at $formatted_datetime")

            org_field =
                isnothing(org_data) ?
                Discord.EmbedField(;
                    name="**Organizations**", value="No information", inline=false
                ) :
                ==(length(org_data), 1) ?
                Discord.EmbedField(;
                    name="**Organization**",
                    value="[$(org_data[1][:name])]($(org_data[1][:url]))",
                    inline=false,
                ) :
                Discord.EmbedField(;
                    name="**Organizations**",
                    value="[$(org_data[1][:name])]($(org_data[1][:url])) | [$(org_data[2][:name])]($(org_data[2][:url]))",
                    inline=false,
                )
            repo_field = Discord.EmbedField(;
                name="**Repos**",
                value="[$public_repos]($(github_profile_url)?tab=repositories)",
                inline=true,
            )
            follower_field = Discord.EmbedField(;
                name="**Followers**",
                value="[$followers]($(github_profile_url)?tab=followers)",
                inline=false,
            )
            following_field = Discord.EmbedField(;
                name="**Following**",
                value="[$following]($(github_profile_url)?tab=following)",
                inline=true,
            )
            twitter = json_data[:twitter_username]
            twitter_field =
                isnothing(twitter) ?
                Discord.EmbedField(;
                    name="**Twitter**", value="Not available", inline=true
                ) :
                Discord.EmbedField(;
                    name="**Twitter**",
                    value="[@$(twitter)](https://twitter.com/$(twitter))",
                    inline=true,
                )
            website = json_data[:blog]
            website_field =
                ==(website, "") ?
                Discord.EmbedField(;
                    name="**Website**", value="Not available", inline=true
                ) :
                Discord.EmbedField(; name="**Website**", value=website, inline=true)

            all_fields = [
                twitter_field,
                website_field,
                repo_field,
                org_field,
                follower_field,
                following_field,
            ]

            embed = Discord.Embed(;
                title="**$(username)'s Github Profile**",
                description=bio,
                color=rand(0:16777215),
                fields=all_fields,
                footer=footer,
                thumbnail=avatar,
                url=github_profile_url,
            )
            reply(c, m, embed)
        else
            reply(c, m, "Sorry. User does not exist. You are probably daydreaming.")
        end
    catch ex
        @show ex
        reply(c, m, "Search failed. Either user does not exist or account is private.")
    end
    return nothing
end
