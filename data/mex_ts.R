library(dplyr)

mex_ts_tbl <- tribble(
  ~code, ~description, ~seasonal, ~ units,
  "MAUINSA", "Mexican Auto Imports", TRUE, "Thousands of Units",
  "HOHWMN03MXM661N", "Hours Worked: Manufacturing: Monthly for Mexico", TRUE, "Index 2015=100",
  "OPCNSH01MXM661N", "Total Cost of Social Housing Construction for Mexico", FALSE, "Index 2015=100",
  "LCEAMN04MXM661N", "Manufacturing: Real Monthly Earnings for Mexico", TRUE, "Index 2015=100",
  "LRHUTTFEMXM156N", "Monthly Unemployment Rate Female: 15 Years or over for Mexico", TRUE, "Percent",
  "LRHUTTMAMXM156N", "Monthly Unemployment Rate Male: 15 Years or over for Mexico", TRUE, "Percent",
  "MEDLISPRIPERSQUFEE33020", "Median Listing Price per Square Feet in Mexico, MO (CBSA)", FALSE, "USD",
  "IMPMX", "U.S. Imports of Goods by Customs Basis from Mexico", TRUE, "Millions of Dollars",
  "MEXPRMNTO01IXOBM", "Manufacturing for Mexico", TRUE, "Index 2015=100",
  "MEXXTIMVA01NCMLM", "Imports: Commodities for Mexico", FALSE, "Mexican Peso"
)

mex_ts_tbl

mex_ts_names <- mex_ts_tbl |> 
  pull(code)

mex_ts_names