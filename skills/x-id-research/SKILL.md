---
name: x-id-research
description: Research creator information using X (Twitter) ID. Fetches X profile, searches web for additional info, and organizes findings into a structured summary. Use when user provides an X/Twitter username and wants to gather information about that creator.
---

# X ID Research

Research a creator's information starting from their X (Twitter) ID.

## Workflow

### Step 1: Fetch X Profile

Fetch `https://x.com/<x_id>` to extract:
- Display name
- Bio/description
- Follower count
- Join date
- Links to other platforms (Fantia, OnlyFans, MyFans, CandFans, etc.)

### Step 2: Extract Creator Name

From the X profile, extract the Japanese name. Use this name for web searches.

### Step 3: Web Search

Search for the creator using these queries (in order):

1. `<creator_name>` - Basic search
2. `<creator_name> fantia` - Fantia fan club
3. `<creator_name> onlyfans` - OnlyFans profile
4. `<creator_name> myfans` - MyFans profile
5. `<creator_name> candfans` - CandFans profile
6. `<creator_name> Instagram` - Instagram profile
7. `<creator_name> cosplayer` or `<creator_name> アイドル` - Additional context

### Step 4: Organize Findings

Compile all gathered information into a structured summary:

```
## Research Summary: <x_id>

### Basic Info
- Name: <name>
- Region: <region>
- X: <x_id> (<follower_count> followers)

### Platforms Found
- [Platform]: <link>

### Additional Info
- <any other findings>
```

## Output Format

Return findings as a structured summary suitable for updating `src/meta/list.yaml` and creating a creator file.

## Example Usage

User: "Get info for x_id bu_ivv"

1. Fetch https://x.com/bu_ivv
2. Extract name: "りお♡" / "bu_ivv"
3. Search for "bu_ivv" on web
4. Find Fantia, MyFans, CandFans links
5. Return structured summary
