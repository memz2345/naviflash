package com.memz2345.navi.flash

import androidx.annotation.DrawableRes
import androidx.annotation.StringRes

   
                               
  
                                                 
                                                       
  
                                                    
                                                             
                                      
                                 
                                                 
   
data class ShortcutCatalogEntry(
    val id: String,
    val action: String,
    @StringRes val shortLabel: Int,
    @StringRes val longLabel: Int,
    @DrawableRes val icon: Int,
)

object ShortcutCatalog {
                                   
    const val MAX_SHORTCUTS = 5

                                                        
    const val PREFS_KEY = "flutter.appShortcutIds"

                                           
    val DEFAULT_IDS: List<String> = listOf("search", "offline", "recommend")

                               
    val entries: List<ShortcutCatalogEntry> = listOf(
        ShortcutCatalogEntry(
            id = "search",
            action = "search",
            shortLabel = R.string.shortcut_search,
            longLabel = R.string.shortcut_search_long,
            icon = R.drawable.ic_shortcut_search,
        ),
        ShortcutCatalogEntry(
            id = "recommend",
            action = "recommend",
            shortLabel = R.string.shortcut_recommend,
            longLabel = R.string.shortcut_recommend_long,
            icon = R.drawable.ic_shortcut_recommend,
        ),
        ShortcutCatalogEntry(
            id = "dynamics",
            action = "dynamics",
            shortLabel = R.string.shortcut_dynamics,
            longLabel = R.string.shortcut_dynamics_long,
            icon = R.drawable.ic_shortcut_dynamics,
        ),
        ShortcutCatalogEntry(
            id = "history",
            action = "history",
            shortLabel = R.string.shortcut_history,
            longLabel = R.string.shortcut_history_long,
            icon = R.drawable.ic_shortcut_history,
        ),
        ShortcutCatalogEntry(
            id = "offline",
            action = "offline",
            shortLabel = R.string.shortcut_offline,
            longLabel = R.string.shortcut_offline_long,
            icon = R.drawable.ic_shortcut_offline,
        ),
    )

    private val byId = entries.associateBy { it.id }

    fun entryOf(id: String): ShortcutCatalogEntry? = byId[id]
}
