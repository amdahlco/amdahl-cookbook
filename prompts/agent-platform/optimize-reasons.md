# Reasons on each change

**What this does**: Reads the reasons Amdahl records for what it wrote. A rewrite result carries `changes` (why each edit was made), `added_claims` (which sentences rest on a line you did not send) and `placeholders` (fill-in slots still in the text). A prompt run carries its own `changes`. This page says what each field holds and when it is absent.

**When to use it**: You show Amdahl's message to a person, or you check it in code, and you want the reason beside each edit. This applies to every email in a [sequence](improve-a-sequence.md) too.

## Why this matters

A rewrite you cannot explain is a rewrite nobody approves. These fields give the reason for each edit in the sender's terms, and they say what to fill in before the text goes out. Show them beside the message. A summary in your own words drops the qualifiers.

The values in the examples on this page are made up.

## The operation

These fields come back from `messages.optimize` (`POST /messages/optimize`, MCP `optimize_message`) and from a prompt run read (`GET /messages/optimize_prompt/{id}`, MCP `get_prompt_run`).

## `changes` on a rewrite

```json
{
  "ok": true,
  "outcome": "rewritten",
  "what_changed": "Cut the claim about shipping faster and opened on the rollout problem.",
  "changes": [
    {
      "before": "We help engineering teams ship faster with rollout tooling.",
      "after": null,
      "why": "Nothing in your conversations backs the claim.",
      "why_cut": "The claim has no source, so a reader cannot check it."
    },
    {
      "before": null,
      "after": "Northwind posted two platform roles this month.",
      "why": "From the fact you sent.",
      "why_added": "It gives a reason to write now."
    }
  ]
}
```

Each row is `{before, after, why, why_cut?, why_added?}`.

- **`before`** is word for word in your draft. It is `null` for a sentence Amdahl added.
- **`after`** is word for word in `message`. It is `null` for a sentence Amdahl cut.
- **`why_cut`** says why the old text went. **`why_added`** says why the new text is better. Each is left out when nothing is on record for it.
- **`why`** is the older single reason. A row without it is dropped.
- **Verbatim is checked.** The server drops a row whose `before` is not in your draft or whose `after` is not in `message`. You can match each row against your own diff.
- **Order and size.** Rows are in message order, and there are at most 12.
- **A change with nothing on record has no row.** `changes` is not a full diff.

Read `changes` by its state:

| `changes` | Meaning |
|---|---|
| `[...]` with rows | the recorded reasons |
| `[]` | the draft came back, or no change has a recorded reason |
| absent | not computed |

`[]` and absent are different answers. Do not render either as "no changes were made". Read `outcome` and `unchanged` for that.

With no draft, `before` can only be `null`, because there is no draft text to match. A call that sends no `message` is described in [Write a sequence from a goal and a plan](write-a-sequence.md).

`what_changed` is one sentence on what the rewrite changed and why. It is present only when `outcome` is `rewritten`.

**Grade mode has no `changes`.** A grade (`mode: "grade"`) writes nothing. Its result has `grade` and `disclosures`, and no `message`. See [Grade and report](../../skills/grade-and-report/SKILL.md).

## `added_claims`

```json
{
  "added_claims": [
    {
      "sentence": "Northwind posted two platform roles this month.",
      "sources": [
        { "id": "src_1", "tag": "caller", "text": "Northwind posted two platform engineering roles this month." }
      ]
    }
  ]
}
```

Each row is a sentence of `message` that rests on a line your request did not send, such as a stored value, a stored offer or proof, a CRM note or a public fact. `sources` lists those lines as `{id, tag, text}`. `tag` is `null` when the source has none. `[]` means no sentence rests on such a line. When the optimizer sends no list, the field is absent.

Show these before the text goes out. They are the sentences the sender did not write and may not have seen.

## <a id="open-slots"></a>Open slots: `placeholders`

A message can still hold a slot that stands for a missing fact, such as `[Last Name]`, `{first_name}`, `<NAME>`, `XX%` or `TBD`. `placeholders` lists each one as `{placeholder, asks, source}`.

| Field | Notes |
|---|---|
| `placeholder` | the slot, exactly as `message` holds it |
| `asks` | one plain question that names the missing fact, safe to put to the sender |
| `source` | `caller` when your own input held the same slot (a merge field, or a link you paste later). `writer` when only the returned message holds it |

- A non-empty list means the message is not ready to send. Fill each slot from what you know, or ask the sender `asks`.
- Amdahl returns `message` as it is. It does not fill the slot for you.
- A slot does not change `outcome`.
- Amdahl finds slots with code, not a model. A markdown link, `[sic]`, a footnote and text in code are not slots.
- `[]` means checked and none found. When the field is absent, it was not checked.

A greeting with a merge tag in your draft is kept as written. Nothing more is documented about merge tags, so read `placeholders` and `source` rather than assume. If your sequencer fills a slot later, `source: "caller"` tells you the slot came from your own input.

## Reasons on a prompt run

`optimize_prompt` improves a reusable prompt. Its read, `GET /messages/optimize_prompt/{id}`, carries `changes` when `outcome` is `improved`:

```json
{
  "outcome": "improved",
  "prompt": "<the revised prompt>",
  "changes": [
    { "before": null, "after": "Name one result from a team like theirs.", "why_added": "Aims at a failed check, with its held-out counts." },
    { "before": "Always mention pricing.", "after": null, "why_cut": "Emails written with this line failed the check." }
  ]
}
```

- Each row is `{before, after, why_cut?, why_added?}`. There is no `why`.
- Each row has at least one reason. A row with none is dropped.
- `before` is `null` for an added line. `after` is `null` for a cut line, and it is word for word in the revised `prompt`.
- At most 12 rows.
- `changes` is absent when `outcome` is `unchanged` or `graded`, and from an older optimizer.

## Tips

- **Show the reasons with the text.** A person approves an edit they can see the reason for.
- **Branch on `outcome` first.** `kept` means your draft came back and `message` is your own text.
- **Do not edit `message` to match a row.** The checks ran on the text as returned. The one edit to make is filling a `placeholders` slot.

## See also

- [Improve a sequence](improve-a-sequence.md) and [Write a sequence from a goal and a plan](write-a-sequence.md): where these fields appear in a loop.
- [Grade and report](../../skills/grade-and-report/SKILL.md): the grade result and its disclosures, and `optimize_prompt` runs.
- [Agent platform overview](README.md): the doors, the scopes, the surface.
