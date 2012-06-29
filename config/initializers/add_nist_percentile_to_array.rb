# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file


class Array

  # nist calculation: http://www.itl.nist.gov/div898/handbook/prc/section2/prc252.htm
  def nist_percentile(percentile)
    sorted = self.dup.sort!
    length = sorted.length
    n = (length+1)
    p_sub_n = (percentile/100) * n
    k = p_sub_n.floor
    if(k == 0)
      sorted[0]
    elsif(k == length)
      sorted[k-1]
    else
      d = (p_sub_n) - k
      (sorted[k-1] + d * (sorted[k] - sorted[k-1]))        
    end
  end
  
end
