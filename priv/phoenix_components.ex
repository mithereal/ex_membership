defmodule Membership.Phoenix.Components do
  use Phoenix.Component

  slot(:inner_block, required: true)

  def plans(assigns) do
    ~H"""
      <section class="plans">
          <div class="flex flex-wrap items-center justify-center max-w-4xl mx-auto gap-4 sm:gap-0">
            <div class="h-screen w-screen p-10">
            {render_slot(@inner_block)}
            </div>
            </div>
      </section>
    """
  end

  attr(:price, :float, required: true, doc: "price")
  attr(:name, :string, required: true, doc: "name")
  attr(:url, :string, required: true, doc: "url")
  slot(:inner_block, required: false)

  def plan(assigns) do
    ~H"""
      <div class="w-full p-6 rounded-lg shadow-xl sm:w-1/2 bg-gradient-to-br sm:p-8">
           <div class="flex flex-col items-start justify-between gap-4 mb-6 lg:flex-row">
          <div>
            <h3 class="text-2xl font-semibold jakarta sm:text-4xl">{@name}</h3>
          </div>
        </div>
        <div class="mb-4 space-x-2">
          <span class="text-4xl font-bold">{@price}</span>
        </div>
        <ul class="mb-6 space-y-2 text-indigo-100">
        {render_slot(@inner_block)}
        </ul>
        <a href={@url}
           class="block px-8 py-3 text-sm font-semibold text-center transition duration-100 bg-black rounded-lg outline-none bg-opacity-20 hover:bg-opacity-30 md:text-base">Get
          Started for Free</a>
      </div>
    """
  end

  attr(:price, :float, required: true, doc: "price")
  attr(:name, :string, required: true, doc: "name")
  attr(:url, :string, required: true, doc: "url")
  slot(:inner_block, required: false)

  def highlighted_plan(assigns) do
    ~H"""
        <div class="w-full p-6 rounded-lg shadow-xl sm:w-1/2 bg-gradient-to-br from-blue-600 to-purple-600 sm:p-8">
       <div class="flex flex-col items-start justify-between gap-4 mb-6 lg:flex-row">
          <div>
            <h3 class="text-2xl font-semibold text-amber-300 jakarta sm:text-4xl">{@name}</h3>
          </div>
        </div>
        <div class="mb-4 space-x-2">
          <span class="text-4xl font-bold">{@price}</span>
        </div>
        <ul class="mb-6 space-y-2 text-indigo-100">
        {render_slot(@inner_block)}
        </ul>
        <a href={@url}
           class="block px-8 py-3 text-sm font-semibold text-center text-white transition duration-100 bg-white rounded-lg outline-none bg-opacity-20 hover:bg-opacity-30 md:text-base">Get
          Started for Free</a>
      </div>
    """
  end

  attr(:name, :string, required: true, doc: "feature name")

  def feature(assigns) do
    ~H"""
         <li class="flex items-center gap-1.5">
            <svg xmlns="http://www.w3.org/2000/svg" class="flex-shrink-0 w-5 h-5" viewBox="0 0 20 20"
                 fill="blue">
              <path fill-rule="evenodd"
                    d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
                    clip-rule="evenodd"></path>
            </svg>
            <span class="text-amber-950">{@name}</span>
          </li>
    """
  end

  def highlighted_feature(assigns) do
    ~H"""
         <li class="flex items-center gap-1.5">
            <svg xmlns="http://www.w3.org/2000/svg" class="flex-shrink-0 w-5 h-5" viewBox="0 0 20 20"
                 fill="currentColor">
              <path fill-rule="evenodd"
                    d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
                    clip-rule="evenodd"></path>
            </svg>
            <span class="">{@name}</span>
          </li>
    """
  end
end
