Starting vault from scratch is annoying.

In postgres we did the following:

Created a user called vault:
```
CREATE USER vault WITH ENCRYPTED PASSWORD '<password-here>';
CREATE DATABASE vault;
GRANT ALL ON DATABASE vault TO vault;
ALTER DATABASE vault OWNER TO vault;
```

Then as the `vault` user we executed the following sql, which comes from the `postgresql` storage docs for Vault:

```sql
CREATE TABLE IF NOT EXISTS vault_kv_store (
  parent_path TEXT COLLATE "C" NOT NULL,
  path        TEXT COLLATE "C",
  key         TEXT COLLATE "C",
  value       BYTEA,
  CONSTRAINT pkey PRIMARY KEY (path, key)
);

CREATE INDEX IF NOT EXISTS parent_path_idx ON vault_kv_store (parent_path);
```

We then started the service and initialized Vault from the web UI over the tailscale network.
