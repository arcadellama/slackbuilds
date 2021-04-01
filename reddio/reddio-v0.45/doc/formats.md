# Format variables

The following variables can be used in the `format` config variable
or as a parameter for the print command `-f` option.

The entire format string is evaluated so `${parameter:+word}` parameter
expansion can be used as a crude form of conditional statement, to only
print output, when a certain variable is set. For example, to print
'Upvoted' when the user has upvoted a post, but otherwise print nothing,
the format `${up:+Upvoted }` can be used.

Check out the [example config](config.EXAMPLE) in the doc folder to see how this is applied
in a complex manner.



## Colors and formatting

### ANSI colors

| variable     | description          |
| ------------ | -------------------- |
| $fg0 .. $fg7 | foreground color 0-7 |
| $bg0 .. $bg7 | background color 0-7 |

### Misc

| variable | description       |
| -------- | ----------------- |
| $rst     | Reset             |
| $bld     | Bold              |
| $it      | Italic            |
| $ul      | Underline         |
| $rev     | Reverse video     |
| $tab     | Tab               |
| $cr      | Carriage return   |
| $nl      | Newline           |
| $num     | Item index number |



## General booleans (1 or empty)

| variable | description |
| -------- | ----------- |
| $is_comments | True when listing a comment thread and is normally used to conditionally print the selfpost text |
| $is_mixed    | When printing a comment thread, the listing includes a submission (t3) and comments (t1) |
| $is_comment  | The item is a comment (t1) |
| $is_continue | The item is a continue item |
| $is_link     | The item is a link (t3) |
| $is_more     | The item is a "load more comments" item |
| $is_msg      | The item is a message (t4) |
| $is_sub      | The item is a subreddit (t5) |
| $is_user     | The item is a user (t2) |



## Other common/shared variables

| variable        | description |
| --------------- | ----------- |
| $author         | Authors name of a thing |
| $id             | Id of a thing |
| $title          | Title of a thing |
| $text           | Body text of a thing |
| $created        | Creation time in seconds since the epoch |
| $created_pretty | Human readable creation time |
| $edited         | Last edited time in seconds since the epoch |
| $edited_pretty  | Human readable time a thing was edited |
| $archived       | The comment or submission is archived |
| $gilded         | How often a comment or submission was gilded (Platinum/Gold/Silver) |
| $saved          | You have the comment or submission saved |
| $subreddit      | The subreddit a comment or submission was posted on |
| $depth          | The depth in a comment or message thread |
| $parent_id      | The parents id. Can be a comment, message or submission |

### Voting

| variable      | description |
| ------------- | ----------- |
| $voted        | Your vote direction "up", "down" or empty |
| $up           | Boolean, whether or not you upvoted |
| $down         | Boolean, whether or not you downvoted |
| $score        | Score of a thing |
| $ups          | Amount of upvotes a thing received |
| $upvote_ratio | Upvote ratio of a thing |
| $show_score   | Boolean, whether or not the score should be shown |
| $hide_score   | Boolean, whether or not the score should be hidden |

### User types

| variable       | description |
| -------------- | ----------- |
| $distinguished | A, M, S or empty for Admin/Moderator/Special |
| $admin         | Boolean, whether or not a user is an admin |
| $moderator     | Boolean, whether or not a user is a moderator |
| $special       | Boolean, whether or not a user has special permissions |



## Comments (t1) specific

### Booleans

| variable      | description |
| ------------- | ----------- |
| $is_submitter | The comment poster is also the submitter of the link |
| $locked       | The comment thread is locked |
| $stickied     | The comment is stickied (usually moderator posts) |

### Numbers

| variable          | description |
| ----------------- | ----------- |
| $controversiality | The controversiality of the comment |

### Strings

| variable    | description |
| ----------- | ----------- |
| $context    | ??? |
| $link_id    | The id of the submission the comment belongs to |
| $link_title | The title of the submission the comment belong to |



## User (t2) specific

### Booleans

| variable        | description |
| --------------- | ----------- |
| $subscribed     | You are subscribed to the user |
| $is_employee    | The user is a Reddit employee |
| $is_friend      | The user is your friend |
| $is_gold        | The user is a gold member |
| $is_mod         | The user is a moderator |
| $verified       | The user is verified |
| $verified_email | The users email is verified |

### Numbers

| variable       | description |
| -------------- | ----------- |
| $comment_karma | The users global comment karma |
| $link_karma    | The users global link karma |

### Strings

| variable | description |
| -------- | ----------- |
| $name    | Username |



## Submission (t3) specific

### Booleans

| variable             | description |
| -------------------- | ----------- |
| $clicked             | Not sure the difference to $visited |
| $hidden              | The submission is hidden |
| $is_meta             | The submission is a meta post |
| $is_self             | The submission is a self-post instead of a link |
| $locked              | The submission is locked |
| $over18              | The submission is not suited for work |
| $pinned              | The submission is pinned |
| $quarantine          | The submission is quarantined |
| $spoiler             | The submission includes spoilers |
| $stickied            | The submission is stickied |
| $visited             | You visited The submission (non functional?) |
| $is_original_content | ??? |

### Numbers

| variable        | description |
| --------------- | ----------- |
| $downs          | Amount of downvotes The submission received |
| $num_comments   | Amount of comments |
| $num_crossposts | Amount of crossposts |

### Strings

| variable | description |
| -------- | ----------- |
| $tags    | A list of tags. "[NSFW]" for not suited for work, "[S]" for stickied etc. |
| $domain  | The domain of the submitted link |
| $url     | The url of the submitted link |



## Message (t4) specific

### Booleans

| variable     | description |
| ------------ | ----------- |
| $new         | The message is unread |
| $was_comment | ??? |

### Strings

| variable      | description |
| ------------- | ----------- |
| $dest         | Receiver of the message |
| $first_msg_id | Id of the top-level message |
| $subject      | The subject of the top-level message |
| $subreddit    | From which subreddit a mod-message was sent |



## Subreddit (t5) specific

### Booleans

| variable          | description |
| ----------------- | ----------- |
| $over18           | The subreddits content is not suited for work |
| $quarantine       | The subreddit is quarantined |
| $spoilers_enabled | It's possible to mark submissions as spoiler on the subreddit |
| $favorited        | You favorited the subreddit |
| $banned           | You are banned from the subreddit |
| $contributor      | You are a contributor on this subreddit |
| $moderator        | You are a moderator in this subreddit |
| $muted            | You are muted on this subreddit |
| $subscribed       | You are subscribed to the subreddit |
| $wiki_enabled     | The wiki is enabled on this subreddit |

### Numbers

| variable         | description |
| ---------------- | ----------- |
| $active_accounts | Amount of registered users active on the subreddit |
| $active_users    | Total amount of users active on the subreddit |
| $subscribers     | Amount of users subscribed to the subreddit |

### Strings

| variable      | description |
| ------------- | ----------- |
| $name         | The name of the subreddit |
| $title        | The title of the subreddit |
| $type         | Public, private etc. |
| $description  | The subreddits description |
| $header_title | The subreddits header title |
| $submit_text  | The text usually shown when submitting to the subreddit |
| $text         | Usually the text in the sidebar of the subreddit |



## More

### Numbers

| variable | description |
| -------- | ----------- |
| $count   | Amount of comments |

### Strings

| variable  | description |
| --------- | ----------- |
| $children | Comma delimited list of comment ids |
