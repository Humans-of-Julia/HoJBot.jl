"""
    _github_organization_data(org_data::JSON3.Array)

Retrieves organization data of the user. If there is none, returns nothing, otherwise only retrieve one if there is only one, and retrieve two if there is more than one

"""
function _github_organization_data(org_data::JSON3.Array)
    ==(length(org_data), 0) && return nothing
    if ==(length(org_data), 1)
        first_org_response = HTTP.get(org_data[1]["url"])
        first_org_response_body = String(first_org_response.body)
        first_org_json_data = JSON3.read(first_org_response_body)
        return [Dict(
            :name => first_org_json_data[:name], :url => first_org_json_data[:html_url]
        )]
    elseif >(length(org_data), 1)
        # Show only two

        first_org_response = HTTP.get(org_data[1]["url"])
        first_org_response_body = String(first_org_response.body)
        first_org_json_data = JSON3.read(first_org_response_body)
        second_org_response = HTTP.get(org_data[2]["url"])
        second_org_response_body = String(second_org_response.body)
        second_org_json_data = JSON3.read(second_org_response_body)
        return [
            Dict(
                :name => first_org_json_data[:name], :url => first_org_json_data[:html_url]
            ),
            Dict(
                :name => second_org_json_data[:name],
                :url => second_org_json_data[:html_url],
            ),
        ]
    end
    return nothing
end

"""
    _github_organization_data(c::Client, m::Message, query::SubString{String})

Searches and retrieves a github organization data. If there is none, replies "Empty query not allowed", otherwise replies with an embed with basic and custom info fields.

"""
function _github_organization_data(c::Client, m::Message, query::SubString{String})
    ==(query, "") && return reply(c, m, "Empty query not allowed")

    # Used a try catch here because similar behavior as in `github_profile.jl`'s comment
    try
        response = HTTP.get(string(GH_API_URL, "orgs/", query))
        if response.status == 200

            response_body = String(response.body)
            json_data = JSON3.read(response_body)
            avatar = Discord.EmbedThumbnail(;
                url=json_data[:avatar_url], height=24, width=24
            )
            name = json_data[:name]
            description =
                json_data[:description] ∈ ("", nothing) ? "No information" :
                json_data[:description]
            html_url = json_data[:html_url]
            public_repos = json_data[:public_repos]
            date_created = json_data[:created_at]
            convert_datetime = ZonedDateTime(date_created, "yyyy-mm-ddTHH:MM:SSz")
            formatted_datetime = string(Date(convert_datetime), UTC)
            footer = Discord.EmbedFooter(; text="Account created at $formatted_datetime")
            twitter = json_data[:twitter_username]
            website = json_data[:blog]
            repo_field = Discord.EmbedField(;
                name="**Repos**", value="[$public_repos]($(html_url))", inline=false
            )
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
            all_fields = [twitter_field, website_field, repo_field]
            embed = Discord.Embed(;
                title="**$(name)'s Github Org Profile**",
                description=description,
                color=rand(0:16777215),
                fields=all_fields,
                footer=footer,
                thumbnail=avatar,
                url=html_url,
            )
            return reply(c, m, embed)
        else
            return reply(c, m, "No org found")
        end
    catch ex
        @show ex
        return reply(c, m, "No org found")
    end
end
