# Episode authoring

NIGHTWIRE does not ship with a fixed episode or story. Add one JSON file per episode in this folder when you are ready.

## Quick start

1. Copy `_episode_template.json`.
2. Rename the copy to something like `episode_01.json`. Do not overwrite the underscore template.
3. Give the episode a unique `id`, a title, a `start_node`, and a `nodes` object.
4. Give every node a `speaker` character ID from `data/characters/roster.json`.
5. Every choice must point to an existing node using `next_id`.
6. Restart the game. ContentManager validates and loads the file automatically.

## Node fields

- `speaker`: character ID or `system`.
- `text`: message body.
- `choices`: array of player choices. Empty means the node is a terminal message.
- `next_id`: optional automatic transition for a node without choices.

## Choice fields

- `text`: text shown to the player.
- `next_id`: destination node ID.
- `trust_changes`: object of character ID to integer trust delta.
- `set_flags`: object of story flag to JSON value.
- `evidence`: evidence IDs to unlock.
- `requires_trust`: object of character ID to minimum trust.
- `requires_flags`: array of flags that must be true.
- `requires_evidence`: array of evidence IDs that must already be unlocked.

The validator rejects malformed JSON structures and missing node destinations. The story engine enforces choice requirements and persists trust, flags, evidence and current episode progress.

## Character IDs

The starter roster contains 20 editable slots named Character 01 through Character 20. Replace their names, roles, biographies, statuses, avatar paths and accent colors in `data/characters/roster.json`, but preserve the unique IDs unless you also update episode references.

## Evidence

Add evidence definitions to `data/evidence/catalog.json`. A choice can unlock an evidence item by its `id`. Evidence IDs may also be unlocked before a catalog description is authored; the dossier will show a safe placeholder.
