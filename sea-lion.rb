$seed = 0
srand $seed

# tuple index meanings
IDX_IDX = 0
FIT_IDX = 1
DATA_IDX = 2

# sea lion optimization algorithm, as described in
# Raja Masadeh, Basel Mahafzah, and Ahmad Sharieh. Sea lion optimization algorithm. International Journal of Advanced Computer Science and Applications
# featuring some insights procured from other implementations:
#  - https://github.com/thieu1995/mealpy
#  - https://github.com/pfnet-research/batch-metaheuristics

def slno(pop: , max_iter: , n_vars: , range: , thresh: 0.25, &fit_fn)
    start_time = Time.now
    # initialize population
    sea_lions = Array.new(pop) {
        # initialize a new n_vars-dimensional vector
        Array.new(n_vars) { rand range }
    }
    
    # calculate fitness for each agent
    # we model sea lions as tuples (idx, fitness, position)
    sea_lions.map!.with_index { |sl, idx| [ idx, fit_fn[sl], sl ] }
    
    # for most problems, pocket_best and best stay lockstep
    pocket_best = best = sea_lions.min_by { |idx, fit, sl| fit }
    
    best_fit_gen = [ [ best[FIT_IDX], best[FIT_IDX] ] ]
    
    max_iter.times { |i|
        # c is decreased linearly starting at 2 and ending at 0
        # for inclusive range [2, 0]
           # c = (max_iter - i - 1) * 2.0 / (max_iter - 1)
        # for exclusive range [2, 0)
        c = (max_iter - i) * 2.0 / max_iter

        # let vec(SL) be the best candidate search agent who has best fitness
        # aka: "prey"
        # best = sea_lions.min_by { |idx, fit, sl| fit }
        
        # calculate sp_leader "using Eq. (3)"
        # people don't really know what the original authors meant
        sp_leader = if true
            # some people use a simple random variable to replace
            rand
        else
            # yet others use a random radius
            radius = rand           # uniform random in [0, 1)
            theta = 2 * Math::PI * radius
            phi   = 2 * Math::PI * (1 - radius)
            v1 = Math::sin theta    # "speed of sound in water"
            v2 = Math::sin phi      # "speed of sound in air"
            sp_leader = (v1 * (1 + v2) / v2).abs
        end
        
        sea_lions.map! { |idx, fit, sl|
        
            if sp_leader < thresh
                # using the distribution with a random radius, this is about 22.9% of the time
                candidate = if c.abs < 1
                    # "dwindling encircling technique"
                    # update location of current search agent by Eq. (1)
                    #  (1) Dist = |2B*P(t) - SL(t)|
                    #  (2) SL(t+1) = P(t) - Dist*C
                    # where P(T) = best solution (prey), SL(t) is the current seal lion,
                    # and B is just a random vector in [0,1]
                    best
                else
                    # choose a random search agent SL_rand
                    # update their location by Eq. (8):
                    #  (7) Dist = |2B*SL_rand(t) - SL(t)|
                    #  (8) SL(t+1) = SL_rand(t) - Dist*C
                    # where SL_rand(t) is a random other sea lion, SL(t) is the current seal lion,
                    # and B is just a random vector in [0,1]
                    
                    # we do not seem to care if we hit a duplicate
                    # sl_rand_idx = ((0...pop).to_a - [idx]).sample
                    sl_rand_idx = rand 0...pop
                    sl_rand = sea_lions[sl_rand_idx]
                end
                # despite being listed separately, both equations work out
                # to be the same, varying whether we use `best` or `sl_rand`
                
                # although the original paper seems to request a random vector, choosing a random
                # scalar improves performance, and seems to also improve the optimization
                nudge = rand
                sl = candidate[DATA_IDX].zip(sl).map { |cand_x, sl_x|
                    # nudge = rand
                    dist = (2 * nudge * cand_x - sl_x).abs
                    next_sl_x = cand_x - dist * c
                }
            else
                # update the location of current search agent by Eq. (6)
                
                # although the original paper seems to request a random vector, choosing a random
                # scalar improves performance, and seems to also improve the optimization
                m = rand(-1.0..1.0)
                sl = best[DATA_IDX].zip(sl).map { |best_x, sl_x|
                    dist = (best_x - sl_x).abs
                    # m = rand(-1.0..1.0)
                    dist * Math::cos(2 * Math::PI * m) + best_x
                }
            end
            
            # many approaches introduce a "normalization step", replacing values outside of the bounds of the search space with random ones that are
            sl.map! { |sl_x|
                if range.include? sl_x
                    sl_x
                else
                    rand range
                end
            }
            
            # update the fitness for the modified position
            fit = fit_fn[sl]
            sl_next = [idx, fit, sl]
            
            # save our bests
            if best[FIT_IDX] > fit
                best = sl_next
            end
            if pocket_best[FIT_IDX] > best[FIT_IDX]
                pocket_best = best
            end
            
            sl_next
        }
        
        # the paper mentions a premature break condition, but it does not seem to make sense:
        # break "if search agent doesn't belong to any SL_leader?"
        
        # record both pocket and best fit for graphing purposes
        best_fit_gen << [ pocket_best[FIT_IDX], best[FIT_IDX] ]
    }
    
    best = sea_lions.min_by { |idx, fit, sl| fit }
    if pocket_best[FIT_IDX] > best[FIT_IDX]
        pocket_best = best
    end
    
    end_time = Time.now
    puts "Elapsed: #{end_time - start_time}s"
    
    # puts "pocket:"
    # p pocket_best
    # puts "best:"
    # p best
    {
        pocket: pocket_best,
        best: best,
        elapsed: end_time - start_time,
        history: best_fit_gen.map(&:last)
    }
end

# F1; V_no = 30; range = [-100, 100]; f_min = 0
# p slno(300, 500, n_vars: 30, range: -10.0..10.0) { |x|
    # x.map { |xi| xi**2 } .sum
# }

method = ARGV[0] || "thresh"

# the function to optimize (minimize)
opt = -> x {
    x_abs = x.map &:abs
    x_abs.sum + x_abs.inject(:*)
}

csv = if method == "n10"
    # 10 individual trials
    results = []
    10.times {
        result = slno(pop: 300, max_iter: 500, n_vars: 30, range: -10.0..10.0, &opt)
        results << result[:history]
    }

    results.transpose.map.with_index { |results, gen|
        [gen, *results].join(",")
    }.join("\n")
elsif method == "thresh"
    # testing different thresholds
    avg_over = 5
    results = []
    # [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9].each { |thresh|
    [0.0, 0.2, 0.4, 0.6, 0.8, 1.0].each { |thresh|
        puts "Testing t = #{thresh}..."
        # average results
        result = []
        avg_over.times { |c|
            puts "#{c+1}/#{avg_over}..."
            result << slno(pop: 300, max_iter: 500, n_vars: 30, range: -10.0..10.0, thresh: thresh, &opt)[:history]
        }
        
        result = result.transpose.map { |row| row.sum / row.size.to_f }
        results << result
    }
    results.transpose.map.with_index { |results, gen|
        [gen, *results].join(",")
    }.join("\n")
else
    raise "no method #{method}"
end

File.write "sea-lion-epoch-data-#{method}.csv", csv
