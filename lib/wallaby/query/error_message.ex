defmodule Wallaby.Query.ErrorMessage do
  alias Wallaby.Query

  @doc """
  Compose an error message based on the error method and query information
  """
  @spec message(Query.t, any()) :: String.t

  def message(%Query{}=query, :not_found) do
    """
    Expected to find #{expected_count(query)}, #{visibility(query)} #{method(query)} '#{query.selector}' but #{result_count(query.result)}, #{visibility(query)} #{short_method(query.method, Enum.count(query.result))} #{result_expectation(query.result)}.
    """
  end
  def message(%{method: method, selector: selector}, :label_with_no_for) do
    """
    The text '#{selector}' matched a label but the label has no 'for'
    attribute and can't be used to find the correct #{method(method)}.

    You can fix this by including the `for="YOUR_INPUT_ID"` attribute on the
    appropriate label.
    """
  end
  def message(%{method: method, selector: selector}, {:label_does_not_find_field, for_text}) do
    """
    The text '#{selector}' matched a label but the label's 'for' attribute
    doesn't match the id of any #{method(method)}.

    Make sure that id on your #{method(method)} is `id="#{for_text}"`.
    """
  end
  def message(%{selector: selector}, :button_with_bad_type) do
    """
    The text '#{selector}' matched a button but the button has an invalid 'type' attribute.

    You can fix this by including `type="[submit|reset|button|image]"` on the appropriate button.
    """
  end
  def message(_, :cannot_set_text_with_invisible_elements) do
    """
    Cannot set the `text` filter when `visible` is set to `false`.

    Text is based on visible text on the page. This is a limitation of webdriver.
    Since the element isn't visible the text isn't visible. Because of that I
    can't apply both filters correctly.
    """
  end
  def message(_, :min_max) do
    """
    The query is invalid. Cannot set the minimum greater than the maximum.
    """
  end

  def help(elements) do
    """
    If you expect to find the selector #{times(length(elements))} then you
    should include the `count: #{length(elements)}` option in your finder.
    """
  end

  @doc """
  Extracts the selector method from the selector and converts it into a human
  readable format
  """
  @spec method(Query.t) :: String.t
  @spec method({atom(), boolean()}) :: String.t

  def method(%Query{conditions: conditions}=query) do
    method(query.method, conditions[:count] > 1)
  end
  def method(_), do: "element"

  def method(:css, true), do: "elements that matched the css"
  def method(:css, false), do: "element that matched the css"

  def method(:select, true), do: "selects"
  def method(:select, false), do: "select"

  def method(:option, true), do: "option fields"
  def method(:option, false), do: "option"

  def method(:fillable_field, true), do: "text inputs or textareas"
  def method(:fillable_field, false), do: "text input or textarea"

  def method(:checkbox, true), do: "checkboxes"
  def method(:checkbox, false), do: "checkbox"

  def method(:radio_button, true), do: "radio buttons"
  def method(:radio_button, false), do: "radio button"

  def method(:link, true), do: "links"
  def method(:link, false), do: "link"

  def method(:xpath, true), do: "elements that matched the xpath"
  def method(:xpath, false), do: "element that matched the xpath"

  def method(:button, true), do: "buttons"
  def method(:button, false), do: "button"

  def method(:file_field, true), do: "file fields"
  def method(:file_field, false), do: "file field"


  def short_method(:css, count) when count > 1,  do: "elements"
  def short_method(:css, count) when count == 0, do: "elements"
  def short_method(:css, _),                 do: "element"

  def short_method(:xpath, count) when count == 1, do: "element"
  def short_method(:xpath, _), do: "elements"

  def short_method(method, count), do: method(method, count != 1)

  @doc """
  Generates failure conditions based on query conditions.
  """
  @spec conditions(Keyword.t) :: list(String.t)

  def conditions(opts) do
    opts
    |> Keyword.delete(:visible)
    |> Keyword.delete(:count)
    |> Enum.map(&condition/1)
    |> Enum.reject(& &1 == nil)
  end

  @doc """
  Converts a condition into a human readable failure message.
  """
  @spec condition({atom(), String.t}) :: String.t | nil

  def condition({:text, text}) when is_binary(text) do
    "text: '#{text}'"
  end
  def condition(_), do: nil

  @doc """
  Converts the visibilty attribute into a human readable form.
  """
  @spec visibility(Query.t) :: String.t

  def visibility(query) do
    if Query.visible?(query) do
      "visible"
    else
      "invisible"
    end
  end

  defp result_count([_]), do: "only 1"
  defp result_count(result), do: "#{Enum.count(result)}"

  defp times(1), do: "1 time"
  defp times(count), do: "#{count} times"

  defp expected_count(query) do
    conditions = query.conditions

    cond do
      conditions[:count] ->
        "#{conditions[:count]}"

      conditions[:minimum] && Enum.count(query.result) < conditions[:minimum] ->
        "at least #{conditions[:minimum]}"

      conditions[:maximum] && Enum.count(query.result) > conditions[:maximum] ->
        "no more then #{conditions[:maximum]}"

      true -> ""
    end
  end

  def result_expectation(result) when length(result) == 1, do: "was found"
  def result_expectation(_), do: "were found"
end