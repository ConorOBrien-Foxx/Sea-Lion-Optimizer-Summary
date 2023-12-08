import numpy as np
from mealpy import FloatVar, SLO
import time

def objective_function(solution):
    return np.sum(np.abs(solution)) + np.prod(np.abs(solution))

n_vars = 30
problem_dict = {
    "bounds": FloatVar(lb=(-10.,) * n_vars, ub=(10.,) * n_vars, name="delta"),
    "minmax": "min",
    "obj_func": objective_function
}

start_time = time.time()

model = SLO.OriginalSLO(epoch=500, pop_size=300)
g_best = model.solve(problem_dict)
print(f"Solution: {g_best.solution}, Fitness: {g_best.target.fitness}")
print(f"Solution: {model.g_best.solution}, Fitness: {model.g_best.target.fitness}")

end_time = time.time()
execution_time = end_time - start_time
print(f"Execution Time: {execution_time} seconds")


"""
Solution: [-0.99435949  0.17091899 -1.04765935  0.15641413  0.2137824   0.01697867
 -3.57543526 -0.46115291  0.14306657  0.04848131 -3.07773163  1.17301091
  0.48191483  0.13004633 -0.01909068 -1.23523081 -1.13639591 -0.13356864
  0.00491439  0.25472828  0.4795826   0.34499294 -0.1759436  -0.15137459
  0.69444825 -4.00330864 -0.8672806  -2.79270862  0.18672677  0.16616936], Fitness: 54.72858027396199


"""