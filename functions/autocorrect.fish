function autocorrect --description "Autocorrect current command line via llama.cpp"
    set -l current (commandline)
    if test -z "$current"
        return
    end

    set -l escaped (string replace --all '"' '\\"' -- $current)
    set -l payload '{"messages":[{"role":"system","content":"You are a spelling corrector. Fix only typos and spelling errors. Do not change wording, punctuation, capitalisation, or meaning. Return only the corrected text with no explanation."},{"role":"user","content":"'"$escaped"'"}]}'

    set -l response (curl -s --max-time 5 http://localhost:8080/v1/chat/completions \
        -H "Content-Type: application/json" \
        -d "$payload" 2>/dev/null)

    if test $status -ne 0; or test -z "$response"
        commandline -f repaint
        return
    end

    set -l corrected
    if type -q jq
        set corrected (echo "$response" | jq -r '.choices[0].message.content // empty' 2>/dev/null)
    else
        set corrected (string match -r '"content"\s*:\s*"([^"]*)"' -- $response)[2]
    end

    if test -n "$corrected"; and test "$corrected" != "$current"
        commandline -- $corrected
    end

    commandline -f repaint
end
