CREATE EXTENSION IF NOT EXISTS citext;

CREATE TABLE person (
    id                          serial          PRIMARY KEY,
    name                        text            not null,
    email                       citext          not null unique,
    timezone                    text            not null,
    is_enabled                  boolean         not null default true,
    is_admin                    boolean         not null default false,
    created_at                  timestamptz     not null default current_timestamp
);

-- Settings for a given user.  | Use with care, add things to the data model when you should.
CREATE TABLE person_settings (
    id                          serial          PRIMARY KEY,
    person_id                   int             not null references person(id),
    name                        text            not null,
    value                       json            not null default '{}',
    created_at                  timestamptz     not null default current_timestamp,

    -- Allow ->find_or_new_related()
    CONSTRAINT unq_person_id_name UNIQUE(person_id, name)
);

CREATE TABLE auth_password (
    person_id                   int             not null unique references person(id),
    password                    text            not null,
    salt                        text            not null,
    updated_at                  timestamptz     not null default current_timestamp,
    created_at                  timestamptz     not null default current_timestamp
);

CREATE TABLE auth_token (
    id                          serial          PRIMARY KEY,
    person_id                   int             not null references person(id),
    scope                       text            not null,
    token                       text            not null,
    created_at                  timestamptz     not null default current_timestamp
);

CREATE TABLE graph (
    id                          serial          PRIMARY KEY,
    person_id                   int             not null references person(id),
    name                        text            not null,
    unit                        text            not null -- lb / kg / st
);

CREATE TABLE graph_settings (
    id                          serial          PRIMARY KEY,
    graph_id                    int             not null references graph(id),
    name                        text            not null,
    value                       json            not null default '{}',

    -- Allow ->find_or_new_related()
    CONSTRAINT unq_graph_id_name UNIQUE(graph_id, name)
);

CREATE TABLE graph_data (
    id                          serial          PRIMARY KEY,
    graph_id                    int             not null references graph(id),
    value                       numeric         not null,
    note                        text            not null,
    ts                          timestamptz     not null default current_timestamp
);


