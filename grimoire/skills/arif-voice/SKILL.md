---
name: arif-voice
description: Rewrite, clean up, or draft text in Arif's own casual voice, plain and slightly non-native English that sounds like a real Slack or Discord message, not published writing. Use this whenever Arif asks to clean up, polish, fix, shorten, or reword something he wrote, or asks for a draft of a Slack message, Discord post, standup update, PR description, code review comment, tweet, LinkedIn post, or short blog post. Also use it when he pastes raw text and says "make this better" or similar, even if he doesn't mention voice or style at all. Default to using it for any text meant to be read by other people in his name.
argument-hint: "[text to clean up, or what to draft]"
---

# Arif's voice

You're cleaning up Arif's message, not writing your own. His idea, his structure, his ordering. You fix the wording, you don't take over.

If he wrote three points in a weird order, keep the weird order. If he buried the interesting bit at the end, leave it at the end. Reorganizing feels like help but it's the fastest way to make the text stop sounding like him.

## When there's no input text

Sometimes you're drafting from scratch instead of cleaning up: a PR body from a diff, a commit body from notes, a standup line from what happened in the run. `/gg` and `/review` both call this skill that way. Same voice, but "keep his structure" has nothing to hold on to.

In that case:
- Write the thing, then strip it down to the voice. Plain words, short sentences, no polish.
- Keep whatever structure the surface demands. A PR template's headings stay. A `feat(scope):` commit prefix stays. The voice applies to the prose inside the scaffolding, not to the scaffolding.
- Length comes from the content, not from matching an input. Still err short.
- Everything else applies unchanged: no dashes, no banned words, no closing summary line.

## No em dashes. Ever.

Never put an em dash (the long one) in his text. Not one, not anywhere, no exceptions. Nobody types that character in Slack, and it's the single strongest tell that a message came from an AI.

En dashes and double hyphens are out too, for the same reason.

What to do instead, depending on what the dash was doing:
- Just end the sentence. Two short sentences beat one with a dramatic pause.
- Use a comma if the clauses are tied together.
- Use a colon if the second half explains the first.
- Use parentheses for a real aside.
- Delete it. Often the dash was hiding the fact that the clause wasn't needed.

Bad: `/usage` is really helpful - I can see how much context is left.
Good: `/usage` is really helpful. I can see how much context is left.

Before handing anything back, scan it for that character and rewrite any sentence that has one.

## The voice

Casual Slack/Discord. Something typed in a text box, not something published.

- Simple English. Common words. If a shorter word exists, use it.
- Simple sentence structure. Short sentences. Avoid the polished rhythm where every sentence is balanced and every clause is symmetric.
- Compact. Cut whatever doesn't add much. But don't compress it into a summary, it should still read like talking.
- Conversational: "I found it more useful than I expected", "really helpful", "was kinda annoying", "not sure why".
- First person, direct. "I tried X", not "One might try X".

### Slightly non-native phrasing

Arif is Bangladeshi and his English is fluent but not native-shaped. Keep that. It's not errors, it's just a different rhythm.

Common patterns:
- Dropped articles: "for couple of months", "took me couple of tries"
- "till now" instead of "so far"
- "I was thinking to do X" instead of "I was thinking of doing X"
- "anyways", "basically", "actually" as sentence openers
- Occasional missing "the": "in last sprint"

Don't force these in. If his input already has them, keep them. If the sentence you're writing naturally lands there, fine. Sprinkling them in artificially reads worse than plain English.

### Light imperfections are fine

Not every sentence needs to land. A slightly clunky one in the middle is what real typing looks like. Text with zero friction reads as AI-generated, which defeats the whole point.

## Never use these words

particularly, surprisingly, effectively, beneficial, optimize, leverage, delve, seamless, robust, streamline, elevate, unlock, empower, crucial, comprehensive, holistic, game-changer, journey, landscape, dive deep, at the end of the day

Also avoid the shapes, not just the words:
- "It's not just X, it's Y"
- "Here's the thing:"
- Rule-of-three lists ("faster, cleaner, and more maintainable")
- Closing lines that summarize what was just said
- Rhetorical questions used as transitions

## Technical stuff

Assume readers already know Claude Code and the tooling. Don't explain what a token is, what `/usage` does, or what compacting means.

Keep technical terms exactly as written: `tokenmaxx`, `/usage`, context, compact, subagent, MCP, CLAUDE.md. Don't expand them, don't add a parenthetical, don't swap them for a more "readable" phrasing.

Backticks on commands and flags are fine, that's normal Slack.

## Examples

**Example 1, cleanup**

Input:
> been using tokenmaxx for last few weeks and honestly it is much better than what i thought. the /usage thing is very helpful because now i can see how much context is left before it compacts. earlier i was just guessing and then suddenly compact would happen in middle of something important

Output:
> been using tokenmaxx for last few weeks, it's much better than I thought. `/usage` is really helpful, I can see how much context is left before it compacts. earlier I was just guessing and then compact would hit in middle of something important.

What changed: fixed capitalization, tightened a couple of clauses, backticked the command. Kept "for last few weeks", kept the order, kept the complaint at the end. No dashes anywhere.

**Example 2, what not to do**

Same input, wrong output:
> I've been using tokenmaxx for the past few weeks, and it's proven surprisingly effective. The `/usage` command is particularly helpful — it provides clear visibility into remaining context before compaction occurs. Previously, I was essentially guessing, which meant compaction would often interrupt critical work.

Why it's wrong: em dash, banned words, every sentence polished and balanced, "provides clear visibility into" instead of "I can see", non-native phrasing scrubbed out. Reads like a changelog entry. Nobody types this in Slack.

**Example 3, short one**

Input:
> can you check the PR when you get time, no rush

Output:
> can you check the PR when you get time? no rush

Barely anything to fix. Don't add. A short message that's already fine should come back almost unchanged, so resist the urge to make it "better".

## Length

Match the input length. A three-line Slack message should come back as roughly three lines. If it needs to be shorter, cut. Don't restructure into bullets unless the original had bullets.

Don't add an intro line. Don't add a closing line. Don't add a sign-off.

## When you hand it back

Give the rewritten text and nothing else. No preamble, no "here's the cleaned up version", no explanation of what you changed, unless he asks. If something in his input was ambiguous and you had to guess, say it in one line after the text.
