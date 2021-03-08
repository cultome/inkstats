class Inkstats::Storage
  def save(battles)
    return if battles.empty?

    fields = battles.first.keys

    inserted = 0

    with_conn do |conn|
      battles.each do |battle|
        r = conn.exec_params(
          "INSERT INTO battles_v1(#{fields.join(', ')}) VALUES (#{fields.map.with_index{ |_, idx| "$#{idx+1}" }.join(', ')}) ON CONFLICT DO NOTHING",
          battle.values_at(*fields)
        )

        inserted += r.cmd_tuples
      rescue Exception => error
        puts "[-] Error: #{error}"
      end
    end

    inserted
  end

  def drop_schema!
    stmts = [
      "DROP TABLE IF EXISTS battles_v1",
      "DROP TYPE specie",
      "DROP TYPE gender",
      "DROP TYPE identify",
      "DROP TYPE lobby",
      "DROP TYPE mode",
      "DROP TYPE rank",
      "DROP TYPE result",
      "DROP TYPE rule",
      "DROP TYPE special_battle",
      "DROP TYPE festival_title",
    ]

    with_conn do |conn|
      stmts.each do |query|
        conn.exec query
      end
    end

    puts "Done!"
  end

  def create_schema!
    stmts = [
      "CREATE TYPE specie AS ENUM ('inklings', 'octolings')",
      "CREATE TYPE gender AS ENUM ('boy', 'girl')",
      "CREATE TYPE identify AS ENUM ('gachi', 'regular')",
      "CREATE TYPE lobby AS ENUM ('standard', 'squad_2', 'squad_4', 'private')",
      "CREATE TYPE mode AS ENUM ('regular', 'gachi', 'league_pair', 'league_team', 'private', 'fes_solo', 'fes_team')",
      "CREATE TYPE rank AS ENUM ('B-', 'B', 'B+', 'A-', 'A', 'A+', 'S')",
      "CREATE TYPE result AS ENUM ('win', 'lose')",
      "CREATE TYPE rule AS ENUM ('turf_war', 'splat_zones', 'tower_control', 'rainmaker', 'clam_blitz')",
      "CREATE TYPE special_battle AS ENUM ('10x', '100x')",
      "CREATE TYPE festival_title AS ENUM ('fanboy', 'defender', 'king')",
      <<-SQL
    CREATE TABLE battles_v1 (
      splatnet_number INT NOT NULL PRIMARY KEY,
      assist INT,
      clout INT,
      death INT,
      elapsed_time INT,
      estimate_gachi_power INT,
      estimate_x_power INT,
      fest_exp INT,
      fest_exp_after INT,
      fest_power INT,
      fest_title INT,
      fest_title_after INT,
      headgear_gear INT,
      headgear_primary_ability INT,
      headgear_secondary_abilities_1 INT,
      headgear_secondary_abilities_2 INT,
      headgear_secondary_abilities_3 INT,
      clothing_gear INT,
      clothing_primary_ability INT,
      clothing_secondary_abilities_1 INT,
      clothing_secondary_abilities_2 INT,
      clothing_secondary_abilities_3 INT,
      shoes_gear INT,
      shoes_primary_ability INT,
      shoes_secondary_abilities_1 INT,
      shoes_secondary_abilities_2 INT,
      shoes_secondary_abilities_3 INT,
      his_team_estimate_fest_power INT,
      his_team_estimate_league_point INT,
      his_team_fest_theme INT,
      his_team_win_streak INT,
      kills INT,
      league_point INT,
      level_after INT,
      level_before INT,
      my_count INT,
      my_points INT,
      my_team_estimate_fest_power INT,
      my_team_estimate_league_point INT,
      my_team_fest_theme INT,
      my_team_win_streak INT,
      points_gained INT,
      rank_exp INT,
      rank_exp_after INT,
      special INT,
      stage INT,
      star_rank INT,
      synergy_bonus INT,
      their_count INT,
      total_clout INT,
      total_clout_after INT,
      turf_inked INT,
      weapon INT,
      worldwide_rank INT,
      x_power_after INT,

      freshness FLOAT,
      my_percent FLOAT,
      their_percent FLOAT,

      gender gender,
      identify_mode identify,
      lobby_type lobby,
      mode mode,
      his_team_nickname TEXT,
      my_team_id TEXT,
      my_team_nickname TEXT,
      principal_id TEXT,
      rank_after rank,
      rank_before rank,
      result result,
      rule rule,
      special_battle special_battle,
      species specie,
      title_after festival_title,
      title_before festival_title,

      end_at TIMESTAMP WITHOUT TIME ZONE,
      start_at TIMESTAMP WITHOUT TIME ZONE,

      knock_out BOOL
    )
      SQL
    ]

    with_conn do |conn|
      stmts.each do |query|
        conn.exec query
      end
    end

    puts "Done!"
  end

  private

  def with_conn
    conn = PG.connect(ENV['DATABASE_URL'])
    yield conn if block_given?
    conn.close
  rescue Exception => error
    conn.close unless conn.nil?
  end
end
