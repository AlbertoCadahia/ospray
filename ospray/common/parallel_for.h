// ======================================================================== //
// Copyright 2009-2015 Intel Corporation                                    //
//                                                                          //
// Licensed under the Apache License, Version 2.0 (the "License");          //
// you may not use this file except in compliance with the License.         //
// You may obtain a copy of the License at                                  //
//                                                                          //
//     http://www.apache.org/licenses/LICENSE-2.0                           //
//                                                                          //
// Unless required by applicable law or agreed to in writing, software      //
// distributed under the License is distributed on an "AS IS" BASIS,        //
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. //
// See the License for the specific language governing permissions and      //
// limitations under the License.                                           //
// ======================================================================== //

#pragma once

//namespace ospray {

#ifdef OSPRAY_USE_TBB
# include <tbb/blocked_range.h>
# include <tbb/parallel_for.h>
#endif

template<typename T>
inline void parallel_for(int nTasks, const T& fcn)
{
#ifdef OSPRAY_USE_TBB
  tbb::parallel_for(tbb::blocked_range<int>(0, nTasks),
                    [&fcn](const tbb::blocked_range<int> &range){
      for (int taskIndex = range.begin();
           taskIndex != range.end();
           ++taskIndex)
          fcn(taskIndex);
    });
#else
# pragma omp parallel for schedule(dynamic)
  for (int taskIndex = 0; taskIndex < nTasks; ++taskIndex) {
    fcn(taskIndex);
  }
#endif
}

//}//namespace ospray