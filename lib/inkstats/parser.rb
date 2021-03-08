class Inkstats::Parser
  def parse(battles)
    battles.map do |battle|
      parse_battle battle
    end
  end

  private

  def parse_battle(data)
    splatnet_number = data['battle_number'].to_i
    version = data.fetch('version', false) # splatfest only
    principal_id = data['player_result']['player']['principal_id']
    lobby_type, mode = identify_lobby data['game_mode']['key'], version
    rule = data['rule']['key']
    stage = data['stage']['id']
    weapon = data['player_result']['player']['weapon']['id']
    result = identify_result data['my_team_result']['key']

    my_percent = data['my_team_percentage']
    their_percent = data['other_team_percentage']
    my_count = data['my_team_count']
    their_count = data['other_team_count']
    knock_out = my_count == 100 || their_count == 100

    identify_mode = data['type']
    turf_inked = data['player_result']['game_paint_point']
    my_points = rule == 'turf_war' && result == 'win' ? turf_inked + 1000 : turf_inked

    kills = data['player_result']['kill_count']
    assist = data['player_result']['assist_count']
    special = data['player_result']['special_count']
    death = data['player_result']['death_count']

    level_before = data['player_result']['player']['player_rank']
    level_after = data['player_rank']
    star_rank = data['star_rank']

    rank_after = data.dig('udemae', 'name')
    rank_before = data.dig('player_result', 'player', 'udemae', 'name')
    rank_exp_after = data.dig('udemae', 's_plus_number')
    rank_exp = data.dig('player_result', 'player', 'udemae', 's_plus_number')

    x_power_after = data['x_power'] unless data.dig('udemae', 'is_x').nil?
    worldwide_rank = data['rank']

    if mode == 'gachi'
      estimate_x_power = data['estimate_x_power']
      estimate_gachi_power = data['estimate_gachi_power']
    end

    elapsed_time = data.fetch('elapsed_time', 180)
    start_at = Time.at data['start_time']
    end_at = Time.at(data['start_time'] + elapsed_time)

    if mode == 'league'
      my_team_id = data['tag_id']
      league_point = data['league_point']
      my_team_estimate_league_point = data['my_estimate_league_point']
      his_team_estimate_league_point = data['other_estimate_league_point']
    end

    freshness = data['win_meter'] if mode == 'regular'

    gender = data['player_result']['player']['player_type']['style']
    species = data['player_result']['player']['player_type']['species']

    if !version && mode == 'fest'
      title_before = data['player_result']['player']['fes_grade']['rank']
      title_after = data['fes_grade']['rank']
      fest_exp_after = data['fes_point']

      # present in pro, 0 in normal
      fest_power = data['fes_power']
      # universal system pre-ver.4. now present in both pro & normal but hidden in normal
      my_team_estimate_fest_power = data['my_estimate_fes_power']
      his_team_estimate_fest_power = data['other_estimate_fes_power']

      my_team_fest_theme = data['my_team_fes_theme']['name']
      his_team_fest_theme = data['other_team_fes_theme']['name']
      fest_title = translate_fest_rank[title_before]
      fest_title_after = translate_fest_rank[title_after]
      fest_exp_after = fest_exp_after
      points_gained = 0

      multiplier = version ? 10 : 1

      # TURF INKED EXP
      points_gained += 1 * multiplier

      # WIN BONUS EXP
      if result == 'victory'
        if data['other_estimate_fes_power'] < 1400
          points_gained += 3 * multiplier
        elsif 1400 <= data['other_estimate_fes_power'] < 1700
          points_gained += 4 * multiplier
        elsif 1700 <= data['other_estimate_fes_power'] < 1800
          points_gained += 5 * multiplier
        elsif 1800 <= data['other_estimate_fes_power'] < 1900
          points_gained += 6 * multiplier
        elsif data['other_estimate_fes_power'] >= 1900
          points_gained += 7 * multiplier
        end
      end

      if version
        synergy_mult = data['uniform_bonus']
        points_gained = round(points_gained * synergy_mult) if synergy_mult > 1
      end

      # SPECIAL CASE - KING/QUEEN MAX
      if title_before == 4 && title_after == 4 && fest_exp_after == 0
        fest_exp = 0
        # SPECIAL CASE - CHAMPION (999) TO KING/QUEEN
      elsif title_before == 3 && title_after == 4
        # fes_point == 0 should always be true (reached max). if reaching max *exactly*,
        # then fest_exp = 999 - points_gained. if curtailed rollover, no way to know
        # e.g. even if user got +70, max (999->0) could have been reached after, say, +20
        fest_exp = nil
      else
        if title_before == title_after # within same title
          fest_rank_rollover = 0
        elsif title_before == 0 && title_after == 1 # fanboy/girl (100) to fiend (250)
          fest_rank_rollover = 10 * multiplier
        elsif title_before == 1 && title_after == 2 # fiend (250) to defender (500)
          fest_rank_rollover = 25 * multiplier
        elsif title_before == 2 && title_after == 3 # defender (500) to champion (999)
          fest_rank_rollover = 50 * multiplier
        end

        fest_exp = fest_rank_rollover + fest_exp_after - points_gained
      end

      # avoid mysterious, fatal -1 case...
      fest_exp = 0 if !fest_exp.nil? && fest_exp < 0
    end

    if version && mode == 'fes'
      # indiv. & team fest_powers in above section
      my_team_win_streak  = data['my_team_consecutive_win']
      his_team_win_streak = data['other_team_consecutive_win']

      special_battle = identify_special_battle data['event_type']['key']

      total_clout_after = data['contribution_point_total'] # after

      if lobby == 'fes_team' # normal
        my_team_nickname = data['my_team_another_name']
        his_team_nickname = data['other_team_another_name']
      end

      # synergy bonus
      synergy_bonus = 1.0 if synergy_mult == 0 # always 0 in pro

      # clout
      clout = data['contribution_point']
      # in pro, = his_team_estimate_fest_power
      # in normal, = turfinked (if victory: +1000) -> = int(round(floor((clout * synergy_bonus) + 0.5)))
      total_clout = total_clout_after - clout # before
    end

    headgear_gear = data['player_result']['player']['head']['id'].to_i
    headgear_primary_ability = data['player_result']['player']['head_skills']['main']['id'].to_i
    headgear_secondary_abilities_1, headgear_secondary_abilities_2, headgear_secondary_abilities_3 = data['player_result']['player']['head_skills']['subs'].map{ |s| s['id'].to_i }
    clothing_gear = data['player_result']['player']['clothes']['id']
    clothing_primary_ability = data['player_result']['player']['clothes_skills']['main']['id']
    clothing_secondary_abilities_1, clothing_secondary_abilities_2, clothing_secondary_abilities_3 = data['player_result']['player']['clothes_skills']['subs'].map{ |s| s['id'].to_i }
    shoes_gear = data['player_result']['player']['shoes']['id']
    shoes_primary_ability = data['player_result']['player']['shoes_skills']['main']['id']
    shoes_secondary_abilities_1, shoes_secondary_abilities_2, shoes_secondary_abilities_3 = data['player_result']['player']['shoes_skills']['subs'].map{ |s| s['id'].to_i }

    {
      assist: assist,
      clout: clout,
      death: death,
      elapsed_time: elapsed_time,
      end_at: end_at,
      estimate_gachi_power: estimate_gachi_power,
      estimate_x_power: estimate_x_power,
      fest_exp: fest_exp,
      fest_exp_after: fest_exp_after,
      fest_power: fest_power,
      fest_title: fest_title,
      fest_title_after: fest_title_after,
      freshness: freshness,
      headgear_gear: headgear_gear,
      headgear_primary_ability: headgear_primary_ability,
      headgear_secondary_abilities_1: headgear_secondary_abilities_1,
      headgear_secondary_abilities_2: headgear_secondary_abilities_2,
      headgear_secondary_abilities_3: headgear_secondary_abilities_3,
      clothing_gear: clothing_gear,
      clothing_primary_ability: clothing_primary_ability,
      clothing_secondary_abilities_1: clothing_secondary_abilities_1,
      clothing_secondary_abilities_2: clothing_secondary_abilities_2,
      clothing_secondary_abilities_3: clothing_secondary_abilities_3,
      shoes_gear: shoes_gear,
      shoes_primary_ability: shoes_primary_ability,
      shoes_secondary_abilities_1: shoes_secondary_abilities_1,
      shoes_secondary_abilities_2: shoes_secondary_abilities_2,
      shoes_secondary_abilities_3: shoes_secondary_abilities_3,
      gender: gender,
      his_team_estimate_fest_power: his_team_estimate_fest_power,
      his_team_estimate_league_point: his_team_estimate_league_point,
      his_team_fest_theme: his_team_fest_theme,
      his_team_nickname: his_team_nickname,
      his_team_win_streak: his_team_win_streak,
      identify_mode: identify_mode,
      kills: kills,
      knock_out: knock_out,
      league_point: league_point,
      level_after: level_after,
      level_before: level_before,
      lobby_type: lobby_type,
      mode: mode,
      my_count: my_count,
      my_percent: my_percent,
      my_points: my_points,
      my_team_estimate_fest_power: my_team_estimate_fest_power,
      my_team_estimate_league_point: my_team_estimate_league_point,
      my_team_fest_theme: my_team_fest_theme,
      my_team_id: my_team_id,
      my_team_nickname: my_team_nickname,
      my_team_win_streak: my_team_win_streak,
      points_gained: points_gained,
      principal_id: principal_id,
      rank_after: rank_after,
      rank_before: rank_before,
      rank_exp: rank_exp,
      rank_exp_after: rank_exp_after,
      result: result,
      rule: rule,
      special: special,
      special_battle: special_battle,
      species: species,
      splatnet_number: splatnet_number,
      stage: stage,
      star_rank: star_rank,
      start_at: start_at,
      synergy_bonus: synergy_bonus,
      their_count: their_count,
      their_percent: their_percent,
      title_after: title_after,
      title_before: title_before,
      total_clout: total_clout,
      total_clout_after: total_clout_after,
      turf_inked: turf_inked,
      # version: version,
      weapon: weapon,
      worldwide_rank: worldwide_rank,
      x_power_after: x_power_after,
    }
  end

  def identify_result(key)
    case key
    when 'victory' then 'win'
    when 'defeat' then 'lose'
    end
  end

  # Just for reference
  def identify_rule(key)
    case key
    when 'turf_war' then 'nawabari'
    when 'splat_zones' then 'area'
    when 'tower_control' then 'yagura'
    when 'rainmaker' then 'hoko'
    when 'clam_blitz' then 'asari'
    end
  end

  def identify_lobby(key, version)
    case key
    when 'regular' # turf war
      ['standard', 'regular']
    when 'gachi' # ranked solo
      ['standard', 'gachi']
    when 'league_pair' # league pair
      ['squad_2', 'gachi']
    when 'league_team' # league team
      ['squad_4', 'gachi']
    when 'private' # private battle
      ['private', 'private']
    when 'fes_solo' # splatfest pro / solo
      [version ? 'fest_pro' : 'standard', 'fest']
    when 'fes_team' # splatfest normal / team
      [version ? 'fest_normal' : 'squad_4', 'fest']
    end
  end

  def identify_special_battle(key)
    case key
    when '10_x_match' then '10x'
    when '100_x_match' then '100x'
    end
  end
end
