# Dina Frontend Git Worktree Management Module

export def --env worktree-add [--branch (-b): string, --force (-f), ...args] {
    # 1. Find the bare repo root (parent of .bare)
    let common_dir = (do { git rev-parse --git-common-dir } | complete | get stdout | str trim)
    if ($common_dir == "") {
        error make {msg: "Not in a git repository or couldn't find common dir"}
    }
    
    let root = ($common_dir | path dirname)
    cd $root 

    # 2. Identify the worktree path from positional args
    let worktree_path = ($args | get 0?)
    if ($worktree_path == null) {
        print "Usage: gdf [-b branch] <path> [<commit>]"
        return
    }

    # 3. Reconstruct git arguments
    mut git_args = []
    if ($branch != null) { $git_args = ($git_args | append ["-b" $branch]) }
    if $force { $git_args = ($git_args | append ["-f"]) }
    $git_args = ($git_args | append $args)

    # 4. Run git worktree add
    git worktree add ...$git_args

    # 5. CD into the folder
    if ($worktree_path | path exists) {
        cd $worktree_path
    } else {
        error make {msg: $"Failed to create worktree at ($worktree_path)"}
    }

    # 6. Link .env files (The "Efficient way")
    let env_source = if ("../.env" | path exists) {
       ".."
    } else if ("../main/.env" | path exists) {
       "../main"
    } else {
        null
    }

    if ($env_source != null) {
        glob $"($env_source)/.env*" | each {|f| 
            let name = ($f | path basename)
            if not ($name | path exists) {
                ^ln -s $f $name 
            }
        }
        print $"Linked .env files from ($env_source)"
    }

    # 7. Open and Start
    agy .
    yarn install
    yarn dev
}
