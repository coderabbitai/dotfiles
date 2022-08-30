#!/usr/bin/env python3

import iterm2

async def main(connection):
    app = await iterm2.async_get_app(connection)
    all_profiles = await iterm2.PartialProfile.async_query(connection)
    for profile in all_profiles:
        if profile.name == "GruvboxDark":
            await profile.async_make_default()
            # set current profile
            full = await profile.async_get_full_profile()
            await app.current_terminal_window.current_tab.current_session.async_set_profile(full)
            return

iterm2.run_until_complete(main)
