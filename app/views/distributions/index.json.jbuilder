json.array!(@distributions) do |distribution|
  json.extract! distribution, :id
  json.url distribution_url(distribution, format: :json)
end
