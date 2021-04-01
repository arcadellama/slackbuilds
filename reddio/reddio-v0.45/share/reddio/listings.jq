def msg_vars:
	# Booleans
	if .new then " new=1" else " new=" end,
	if .was_comment then " was_comment=1" else " was_comment=" end,

	# Numbers
	" created=" + (.created_utc // "" | @text),

	# Strings
	" author=" + (.author // "" | @sh),
	" dest=" + (.dest // "" | @sh),
	" distinguished=" + (.distinguished // "" | @sh),
	" first_msg_id=" + .first_message_name // "",
	" id=" + .name // "",
	" parent_id=" + .parent_id // "",
	" subject=" + (.subject // "" | @sh),
	" subreddit=" + (.subreddit // "" | @sh),
	" text=" + (.body | @sh),
	"\n";

if type == "array" then
	.[].data.children[]
elif type == "object" then
	if .kind == "Listing" then
		.data.children[]
	elif (.json | type) == "object" then
		.json.data.things[]
	else
		.
	end
else
	error("the data does not seem to be a listing")
end |

"kind=" + .kind,

# Comments
if .kind == "t1" then .data |
	if .likes == true then " voted=up up=1 down="
		elif .likes == false then " voted=down up= down=1"
		else " voted= up= down=" end,

	# Booleans
	if .archived then " archived=1" else " archived=" end,
	if .is_submitter then " is_submitter=1" else " is_submitter=" end,
	if .locked then " locked=1" else " locked=" end,
	if .new then " new=1" else " new=" end,
	if .saved then " saved=1" else " saved=" end,
	if .stickied then " stickied=1" else " stickied=" end,
	if .score_hidden then " show_score= hide_score=1"
		else " show_score=1 hide_score=" end,

	# Numbers
	if .controversiality == 0 then " controversiality="
	else " controversiality=" + (.controversiality // "" | @text) end,
	" created=" + (.created_utc // "" | @text),
	" depth=" + (.depth // "0" | @text),
	" downs=" + (.downs // "" | @text),
	" edited=" + (.edited // "" | @text),
	" score=" + (.score // "" | @text),
	" ups=" + (.ups // "" | @text),
	if .gilded == 0 then " gilded="
		else " gilded=" + (.gilded // "" | @text) end,

	# Strings
	" author=" + (.author // "" | @sh),
	" context=" + (.context // "" | @sh),
	" distinguished=" + (.distinguished // "" | @sh),
	" id=" + .name // "",
	" link_id=" + .link_id // "",
	" link_title=" + (.link_title // "" | @sh),
	" parent_id=" + .parent_id // "",
	" subreddit=" + (.subreddit // "" | @sh),
	" text=" + (.body // "" | @sh),
	"\n"

# User
elif .kind == "t2" then .data |
	# Booleans
	if .has_subscribed then " subscribed=1" else " subscribed=" end,
	if .is_employee then " is_employee=1" else " is_employee=" end,
	if .is_friend then " is_friend=1" else " is_friend=" end,
	if .is_gold then " is_gold=1" else " is_gold=" end,
	if .is_mod then " is_mod=1" else " is_mod=" end,
	if .verified then " verified=1" else " verified=" end,
	if .has_verified_email then " verified_email=1"
		else " verified_email=" end,

	# Numbers
	" comment_karma=" + (.comment_karma // "" | @text),
	" created=" + (.created_utc // "" | @text),
	" link_karma=" + (.link_karma // "" | @text),

	# Strings
	" id=t2_" + .id // "",
	" name=" + (.name // "" | @sh),
	"\n"

# Link/Submission
elif .kind == "t3" then .data |
	if .likes == true then " voted=up up=1 down="
		elif .likes == false then " voted=down up= down=1"
		else " voted= up= down=" end,

	# Booleans
	if .archived then " archived=1" else " archived=" end,
	if .clicked then " clicked=1" else " clicked=" end,
	if .hidden then " hidden=1" else " hidden=" end,
	if .is_meta then " is_meta=1" else " is_meta=" end,
	if .is_self then " is_self=1" else " is_self=" end,
	if .locked then " locked=1" else " locked=" end,
	if .over_18 then " over18=1" else " over18=" end,
	if .pinned then " pinned=1" else " pinned=" end,
	if .quarantine then " quarantine=1" else " quarantine=" end,
	if .saved then " saved=1" else " saved=" end,
	if .spoiler then " spoiler=1" else " spoiler=" end,
	if .stickied then " stickied=1" else " stickied=" end,
	if .visited then " visited=1" else " visited=" end,
	if .hide_score then " show_score= hide_score=1"
		else " show_score=1 hide_score=" end,
	if .is_original_content then " is_original_content=1"
		else " is_original_content=" end,

	# Numbers
	" created=" + (.created_utc // "" | @text),
	" downs=" + (.downs // "" | @text),
	" edited=" + (.edited // "" | @text),
	" num_comments=" + (.num_comments // "" | @text),
	" num_crossposts=" + (.num_crossposts // "" | @text),
	" score=" + (.score // "" | @text),
	" ups=" + (.ups // "" | @text),
	" upvote_ratio=" + (.upvote_ratio // "" | @text),
	if .gilded == 0 then " gilded="
		else " gilded=" + (.gilded // "" | @text) end,

	# Strings
	" author=" + (.author // "" | @sh),
	" distinguished=" + (.distinguished // "" | @sh),
	" domain=" + (.domain // "" | @sh),
	" id=" + .name // "",
	" subreddit=" + (.subreddit // "" | @sh),
	" text=" + (.selftext // "" | @sh),
	" title=" + (.title // "" | @sh),
	" url=" + (.url // "" | @sh),
	"\n"

# Message
elif .kind == "t4" then .data |
	" depth=0",
	msg_vars,

	if (.replies | type) == "object" then
		recurse(.replies.data.children[]?) | if .data then .data |
			"kind=t4",
			" depth=1",
			msg_vars
		else empty end
	else empty end

# Subreddit
elif .kind == "t5" then .data |
	# Booleans
	if .over18 then " over18=1" else " over18=" end,
	if .quarantine then " quarantine=1" else " quarantine=" end,
	if .spoilers_enabled then " spoilers_enabled=1"
		else " spoilers_enabled=" end,
	if .user_has_favorited then " favorited=1" else " favorited=" end,
	if .user_is_banned then " banned=1" else " banned=" end,
	if .user_is_contributor then " contributor=1"
		else " contributor=" end,
	if .user_is_moderator then " moderator=1" else " moderator=" end,
	if .user_is_muted then " muted=1" else " muted=" end,
	if .user_is_subscriber then " subscribed=1"
		else " subscribed=" end,
	if .wiki_enabled then " wiki_enabled=1" else " wiki_enabled=" end,

	# Numbers
	" active_accounts=" + (.accounts_active // "" | @text),
	" active_users=" + (.active_user_count // "" | @text),
	" created=" + (.created_utc // "" | @text),
	" subscribers=" + (.subscribers // "" | @text),

	# Strings
	" id=" + .name // "",
	" name=" + (.display_name // "" | @sh),
	" title=" + (.title // "" | @sh),
	" type=" + .subreddit_type // "",
	" description=" + (.public_description // "" | @sh),
	" header_title=" + (.header_title // "" | @sh),
	" submit_text=" + (.submit_text // "" | @sh),
	" text=" + (.description // "" | @sh),
	"\n"

# More comments
elif .kind == "more" then .data |
	# Numbers
	" count=" + (.count // "" | @text),
	" depth=" + (.depth // "0" | @text),

	# Strings
	" id=" + .name // "",
	" parent_id=" + .parent_id // "",
	" children=" + (.children | join(",") // ""),
	"\n"

# Unknown
else error("unknown kind") end
