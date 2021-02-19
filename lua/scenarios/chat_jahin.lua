--textdomain wesnoth-Hero_of_Irdya

function chat_jahin(t)
    -- behave like a [chat] tag
    -- speaker is Jahin, by default
    wesnoth.fire("chat", { speaker = "Jahin", message = t.txt_msg })
end