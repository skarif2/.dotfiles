# Git Bare Clone for Worktrees Module

export def --env clone [--name (-n): string, ...args] {
    let url = ($args | get 0?)
    let name_arg = ($args | get 1?)
    
    if ($url == null) {
        print "Usage: gwc <url> [<name>]"
        return
    }

    let basename = ($url | split row "/" | last)
    let repo_name = if ($name != null) { 
        $name 
    } else if ($name_arg != null) {
        $name_arg
    } else { 
        ($basename | str replace ".git" "") 
    }

    mkdir $repo_name
    cd $repo_name

    # 1. Clone bare repository
    git clone --bare $url .bare

    # 2. Set up .git pointer
    "gitdir: ./.bare" | save -f .git

    # 3. Configure remote fetch
    git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"

    # 4. Fetch all
    git fetch origin

    # 5. Add main/master worktree
    # Check if master or main exists
    let master_exists = (do { git rev-parse --verify master } | complete | get exit_code) == 0
    let default_branch = if $master_exists {
        "master"
    } else {
        "main"
    }

    git worktree add main $default_branch
}
