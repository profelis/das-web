options indenting = 2
options remove_unused_symbols = false
module regex_match shared


require daslib/regex

require server

class RegexMatch : Matcher
  matchRe : Regex
  args: array<string>
  def RegexMatch(var re: Regex)
    matchRe <- re
  def override match(str: string): MatchResult
    args |> clear()
    let res = matchRe |> regex_match(str)
    if res < 0
      return <- [[MatchResult invalid = null]]
    for gr,x in matchRe.groups, range(length(matchRe.groups)-1)
      let grp = regex_group(matchRe, x+1, str)
      args |> push(grp)
    return <- [[MatchResult success = res + 1 ]]
