defmodule Pleroma.HiveModeration do
  alias Pleroma.HTTP
  alias Tesla.Multipart

  def moderate_text(text) do
    url = url()
    req_body = Multipart.add_field(Multipart.new(), "text_data", text)
    req_headers = [
      {"accept", "application/json"},
      {"authorization", "Token " <> token()}
    ]
    {:ok, %{status: 200, body: resp_body}} = HTTP.post(url, req_body, req_headers)
    %{"status" => [status]} = Jason.decode!(resp_body)
    [%{"classes" => classes} | _] = status["response"]["output"]

    result = Enum.reduce(classes, %{}, fn %{"class" => class, "score" => score}, acc ->
      Map.put(acc, class, score)
    end)

    {:ok, result}
  end

  defp url() do
    base_url() <> "/task/sync"
  end

  defp base_url() do
    :pleroma
    |> Application.fetch_env!(:hive)
    |> Keyword.fetch!(:base_url)
  end

  defp token() do
    :pleroma
    |> Application.fetch_env!(:hive)
    |> Keyword.fetch!(:token)
  end
end

# {
#   "id": "43a5eef0-1539-11ec-8d1d-d38403f66b6d",
#   "code": 200,
#   "project_id": 30460,
#   "user_id": 4762,
#   "created_on": "2021-09-14T08:53:43.554Z",
#   "status": [
#     {
#       "status": {
#         "code": "0",
#         "message": "SUCCESS"
#       },
#       "response": {
#         "input": {
#           "hash": "d4f31486288f9b9ad2035351a2dd0f2e",
#           "inference_client_version": "5.0.6",
#           "model": "textmod_mlbert_mlp_multilevel_jul_29_2021",
#           "model_type": "TEXT_CLASSIFICATION",
#           "model_version": 1,
#           "text": "Slut-cunt-dick",
#           "id": "43a5eef0-1539-11ec-8d1d-d38403f66b6d",
#           "created_on": "2021-09-14T08:53:43.391Z",
#           "user_id": 4762,
#           "project_id": 30460,
#           "charge": 0.0005
#         },
#         "custom_classes": [],
#         "text_filters": [
#           {
#             "value": "SLUT",
#             "start_index": 0,
#             "end_index": 4,
#             "type": "profanity"
#           },
#           {
#             "value": "CUNT",
#             "start_index": 5,
#             "end_index": 9,
#             "type": "profanity"
#           },
#           {
#             "value": "DICK",
#             "start_index": 10,
#             "end_index": 14,
#             "type": "profanity"
#           }
#         ],
#         "pii_entities": [],
#         "language": "EN",
#         "moderated_classes": [
#           "sexual",
#           "hate",
#           "violence",
#           "bullying",
#           "spam"
#         ],
#         "output": [
#           {
#             "time": 0,
#             "start_char_index": 0,
#             "end_char_index": 14,
#             "classes": [
#               {
#                 "class": "spam",
#                 "score": 0
#               },
#               {
#                 "class": "sexual",
#                 "score": 3
#               },
#               {
#                 "class": "hate",
#                 "score": 0
#               },
#               {
#                 "class": "violence",
#                 "score": 0
#               },
#               {
#                 "class": "bullying",
#                 "score": 3
#               }
#             ]
#           }
#         ]
#       }
#     }
#   ],
#   "from_cache": false
# }
