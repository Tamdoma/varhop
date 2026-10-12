# Intake: varhop

## Scope
One destination: a keyboard-first prompt launcher for Omarchy that reads a GitHub prompt repo, replacing Notion for prompts. Grouping proposed after the form-factor fork.

## Provenance
- Operator: 2026-10-12 chart-issues invocation

## Source: operator 2026-10-12
I'm using the Omarchy operating system. It's an agent first operating system and you can access its functionality by running the Omarchy skill.

## The problem
- Right now, when I want to get my prompts for AI fast, I always have to go into Notion, which is tedious. Then I have to log in, I have to find them, and then I have to copy them and change the variables inside of the prompts.
- It would be much easier and faster to have an native Omarchy application where I can call it with some combination of keyboard shortcuts, which should be custom. It would be accessed fast with a shortcut, fast instant search, and then focus on the variables and then easy way to copy and paste. The custom prompt library would be a repo that the user connects to.

## Intent
- To have an Omarchi native app that pulls the prompts from my prompt repository and makes it extremely fast to search, change the variables inside of the prompts, and then copy and paste them properly wherever needed.
- To have this app use intuitive keyboard shortcuts so that the power users can learn how to use them fast.
- To replace notion when it comes to having a repo of prompts.
- This should be a simple solution that is lightweight and customizable.

## Details and UI
- The intent is to build a native Omarchi application. It also needs to be built in a way that is compatible with the ecosystem. So we need to figure out what packages it uses to be updated, etcetera something like Mise and Pac-Man.
- The theme colors should inherit everything from the Omarchi theme that was picked by the user. Use Omarchy ways of setting it all up.
- This should be some kind of a pop-up application that presents an overlay with one search box in the beginning focused.
- The first thing that appears after clicking the shortcut button is an overlay above everything else, that is just a simple search box, which would be big enough, simple enough but also look pretty.
- It should be focused by default.
- As soon as the user starts typing, the smart search shows all of the potential prompts as auto complete at the bottom of the box. Something similar to Google auto suggest and how it looks like.
- The user uses the up and down arrows to move across suggestions.
- When the suggestion is clicked, the whole prompt opens.
- The variables will be produced in this format: {{VARIABLE}}. They will be inside of the prompt. As the user presses tab and shift tab, the program will move and select all those variables, including the brackets or the braces. Then when the user changes, the tab button moves to the next or shift tab to the previous position where the variable was. The intent here is to have something that changes the variables really fast.
- The program can go into the background because sometimes the variables will have to be found by the user somewhere inside of their Chrome or browser or something else, then copy and paste it inside.
- The Ctrl plus C button will copy the entire prompt after the variables will change. This is just to make it fast and not add additional buttons for copy pasting. Also, when the copy shortcut is pressed, the app closes.
- There should also be a settings option. I don't know what would be in settings, but I know that the user has to connect to their GitHub and choose the repository that will be able to be read by the program. That means that every repo has to have a standard that the program will accept. We should standardize that so that every repo uses the same categories and subcategories architecture. We can talk about this in during the charting process.
- Overall, the intent is to have something that is accessible very easily by pressing the combination of buttons, searching fast, finding the info fast, changing the variables and copying it into other programs.

## Animation and feel
- Everything needs to be subtly animated to make it feel pleasant to use.
- Small and subtle animations according to Omarchy rules.

## Agent findings
See slots/map-merged.md. Omarchy ships its own instant search-and-copy popups (emojis, clipboard) as Quickshell overlay plugins; third-party plugins install with `omarchy plugin add <git-url>` and update with `omarchy plugin update`. varhop is not registered with akrogon (`akrogon config` repo: none); handoff needs registration.
