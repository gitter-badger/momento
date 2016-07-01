defmodule Momento.Subtract do
  import Momento.Guards
  import Momento.Helpers

  @spec subtract(DateTime.t, integer, atom) :: DateTime.t

  # Singular to plural
  def subtract(datetime, num, :year), do: subtract(datetime, num, :years)
  def subtract(datetime, num, :month), do: subtract(datetime, num, :months)
  def subtract(datetime, num, :day), do: subtract(datetime, num, :days)
  def subtract(datetime, num, :hour), do: subtract(datetime, num, :hours)
  def subtract(datetime, num, :minute), do: subtract(datetime, num, :minutes)
  def subtract(datetime, num, :second), do: subtract(datetime, num, :seconds)
  def subtract(datetime, num, :millisecond), do: subtract(datetime, num, :milliseconds)
  def subtract(datetime, num, :microsecond), do: subtract(datetime, num, :microseconds)


  # Years

  # Base case
  def subtract(%DateTime{year: year} = datetime, num, :years)
  when natural?(num),
  do: %DateTime{datetime | year: year - num}


  # Months

  # Base case
  def subtract(%DateTime{month: month} = datetime, num, :months)
  when natural?(num) and natural?(month - num),
  do: %DateTime{datetime | month: month - num}

  # Many years worth of months
  def subtract(%DateTime{} = datetime, num, :months)
  when positive?(num) and num > 11
  do
    years = floor(num / 12)
    subtract(datetime, years, :years) |> subtract(num - years * 12, :months)
  end

  # Rollover months to the prevous year
  def subtract(%DateTime{year: year, month: month} = datetime, num, :months)
  when positive?(num) and month - num <= 0,
  do: %DateTime{datetime | month: 12 + month - num, year: year - 1}


  # Days

  # Base case
  def subtract(%DateTime{day: day} = datetime, num, :days)
  when natural?(num) and natural?(day - num),
  do: %DateTime{datetime | day: day - num}

  # Many months worth of days
  def subtract(%DateTime{month: month} = datetime, num, :days)
  when positive?(num) and num > days_in_month(month - 1),
  do: subtract(datetime, 1, :months) |> subtract(num - days_in_month(month - 1), :days)

  # Rollover days to the previous month
  def subtract(%DateTime{month: month, day: day} = datetime, num, :days)
  when positive?(num) and day - num < 0,
  do: subtract(%DateTime{datetime | day: days_in_month(month - 1)}, 1, :months) |> subtract(num - day, :days)


  # Hours

  # Base case
  def subtract(%DateTime{hour: hour} = datetime, num, :hours)
  when natural?(num) and natural?(hour - num),
  do: %DateTime{datetime | hour: hour - num}

  # Many days worth of hours
  def subtract(%DateTime{} = datetime, num, :hours)
  when positive?(num) and num > 24
  do
    days = floor(num / 24)
    subtract(datetime, days, :days) |> subtract(num - days * 24, :hours)
  end

  # Rollover hours to be the previous day
  def subtract(%DateTime{hour: hour} = datetime, num, :hours)
  when positive?(num) and num + hour >= 24,
  do: subtract(%DateTime{datetime | hour: 23}, 1, :days) |> subtract(num - hour - 1, :hours)


  # Minutes

  # Base case
  def subtract(%DateTime{minute: minute} = datetime, num, :minutes)
  when natural?(num) and natural?(minute - num),
  do: %DateTime{datetime | minute: minute - num}

  # Many hours worth of minutes
  def subtract(%DateTime{} = datetime, num, :minutes)
  when positive?(num) and num > 60
  do
    hours = floor(num / 60)
    subtract(datetime, hours, :hours) |> subtract(num - hours * 60, :minutes)
  end

  # Rollover minutes to be the previous hour
  def subtract(%DateTime{minute: minute} = datetime, num, :minutes)
  when positive?(num) and negative?(minute - num),
  do: subtract(%DateTime{datetime | minute: 59}, 1, :hours) |> subtract(num - minute - 1, :minutes)


  # Seconds

  # Base case
  def subtract(%DateTime{second: second} = datetime, num, :seconds)
  when natural?(num) and natural?(second - num),
  do: %DateTime{datetime | second: second - num}

  # Many minutes worth of seconds
  def subtract(%DateTime{} = datetime, num, :seconds)
  when positive?(num) and num > 60
  do
    minutes = floor(num / 60)
    subtract(datetime, minutes, :minutes) |> subtract(num - minutes * 60, :seconds)
  end

  # Rollover seconds to be the previous minute
  def subtract(%DateTime{second: second} = datetime, num, :seconds)
  when positive?(num) and negative?(second - num),
  do: subtract(%DateTime{datetime | second: 59}, 1, :minutes) |> subtract(num - second - 1, :seconds)


  # TODO: Milliseconds


  # Microseconds

  # Base case
  def subtract(%DateTime{microsecond: {microsecond, precision}} = datetime, num, :microseconds)
  when natural?(num) and precision === 6 and natural?(microsecond - num),
  do: %DateTime{datetime | microsecond: {microsecond - num, precision}}

  # Many seconds worth of microseconds
  def subtract(%DateTime{microsecond: {_, precision}} = datetime, num, :microseconds)
  when positive?(num) and precision === 6 and num > 999999
  do
    seconds = Float.floor(num / microsecond_factor(precision)) |> round
    subtract(datetime, seconds, :seconds) |> subtract(num - seconds * microsecond_factor(precision), :microseconds)
  end

  # Rollover microseconds to the previous seconds
  def subtract(%DateTime{microsecond: {microsecond, precision}} = datetime, num, :microseconds)
  when natural?(num) and precision === 6 and negative?(microsecond - num),
  do: subtract(%DateTime{datetime | microsecond: {999999, precision}}, 1, :seconds)
    |> subtract(num - microsecond - 1, :microseconds)
end
