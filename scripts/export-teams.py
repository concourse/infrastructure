import json
import sys

def get_identifier(text):
    splitted_text = text.split(":")
    return ":".join(splitted_text[1:])

def get_source(text):
    splitted_text = text.split(":")
    return splitted_text[0]

def get_config(team):
    roles = []

    for k, v in team["auth"].items():
        role = {"name": k}

        for u in v["users"]:
            source = get_source(u)
            if source not in role:
                role[source] = {}

            if "users" not in role[source]:
                role[source]["users"] = []

            role[source]["users"].append(get_identifier(u))


        for g in v["groups"]:
            source = get_source(g)
            if source not in role:
                role[source] = {}

            identifier = get_identifier(g)
            group_type = "orgs"
            if source == "github" and ":" in identifier:
                group_type = "teams"

            if group_type not in role[source]:
                role[source][group_type] = []

            role[source][group_type].append(identifier)

        roles.append(role)

    return {"roles": roles}


filename = sys.argv[1]
output_dir = sys.argv[2]

important_teams = ["main", "contributors", "examples", "dutyfree"]:
with open(filename, "r") as f:
    file_content = json.load(f)

    for team in file_content:
        team_name = team["name"]
        if team_name not in important_teams:
            continue

        path = os.path.path.join(output_dir, team_name+".json")
        with open(path, "w+") as g:
            json.dump(get_config(team), g, indent=4)

