#' Create e-Stat object
#'
#' @param statsDataId e-Stat statsDataId
#' @param appId Your own e-Stat appId
#' @param query query
#' @param url url
#'
#' @import dplyr
#' @import purrr
#' @import tibble
#' @import tidyr
#'
#' @importFrom readr parse_number
#' @importFrom magrittr %<>%
#' @importFrom stringr str_c str_remove str_to_sentence str_glue str_replace_all
#' @importFrom R6 R6Class
#' @importFrom httr GET content
#'
#' @export

e_stat <- R6Class("e_stat",
                  public = list(
                    statsDataId = NULL,
                    query = NULL,
                    url = NULL,
                    total = NULL,
                    info = NULL,
                    key = NULL,
                    value = NULL,
                    note = NULL,
                    data = NULL,
                    initialize = function(statsDataId,
                                          appId,
                                          query = list(),
                                          url = "http://api.e-stat.go.jp/rest/3.0/app/json/getStatsData") {

                      self$statsDataId <- statsDataId
                      self$query <- query %>%
                        c(list(statsDataId = statsDataId,
                               appId = appId,
                               lang = "J"))
                      self$url <- url

                      Sys.sleep(1)
                      GET_STATS_DATA <- GET(url = url,
                                            query = self$query %>%
                                              c(list(cntGetFlg = "Y",
                                                     metaGetFlg = "Y"))) %>%
                        content() %>%
                        pluck("GET_STATS_DATA")

                      if (GET_STATS_DATA$RESULT$STATUS != 0) {
                        stop(GET_STATS_DATA$RESULT$ERROR_MSG)
                      }

                      self$total <- GET_STATS_DATA$STATISTICAL_DATA$RESULT_INF$TOTAL_NUMBER
                      self$info <- GET_STATS_DATA$STATISTICAL_DATA$TABLE_INF %>%
                        enframe() %>%
                        filter(name != "@id") %>%
                        mutate(value = value %>%
                                 map_chr(. %>%
                                           str_c(collapse = "_")))

                      CLASS_OBJ <- GET_STATS_DATA$STATISTICAL_DATA$CLASS_INF$CLASS_OBJ

                      # set key
                      private$key_id <- CLASS_OBJ %>%
                        tail(-1) %>%
                        map_chr(~ .$`@id`)
                      private$key_name <- CLASS_OBJ %>%
                        tail(-1) %>%
                        map_chr(~ .$`@name`)
                      private$key_raw <- CLASS_OBJ %>%
                        tail(-1) %>%
                        map(. %>%
                              pluck("CLASS") %>%
                              bind_rows() %>%
                              rename_with(. %>%
                                            str_remove("^@"))) %>%
                        set_names(private$key_name)
                      self$key <- private$key_raw

                      # set value
                      private$value_raw <- CLASS_OBJ[[1]]$CLASS %>%
                        bind_rows() %>%
                        rename_with(. %>%
                                      str_remove("^@"))
                      self$value <- private$value_raw
                    },
                    get_data = function(limit = 10 ^ 5) {
                      # make key query
                      code_key <- private$key_raw %>%
                        map(. %>%
                              pull(code))
                      query_key <- tibble(id = private$key_id %>%
                                            str_to_sentence() %>%
                                            str_c("cd", .)) %>%
                        rowid_to_column() %>%
                        mutate(code = rowid %>%
                                 map_chr(~ {
                                   if (setequal(self$key[[.x]]$code, code_key[[.x]])) {
                                     NA_character_
                                   } else {
                                     self$key[[.x]]$code %>%
                                       str_c(collapse = ",")
                                   }
                                 }),
                               .keep = "unused") %>%
                        drop_na(code)

                      # make value query
                      code_value <- private$value_raw$code
                      if (setequal(self$value$code, code_value)) {
                        query_value <- tibble()
                      } else {
                        query_value <- tibble(id = "cdTab",
                                              code = self$value$code %>%
                                                str_c(collapse = ","))
                      }

                      query <- bind_rows(query_key,
                                         query_value)

                      if (nrow(query) > 0) {
                        query <- query %>%
                          pull(code) %>%
                          as.list() %>%
                          set_names(query$id) %>%
                          c(self$query)
                      } else {
                        query <- self$query
                      }

                      # get total
                      Sys.sleep(1)
                      GET_STATS_DATA <- GET(url = self$url,
                                            query = query %>%
                                              c(list(cntGetFlg = "Y"))) %>%
                        content() %>%
                        pluck("GET_STATS_DATA")

                      if (GET_STATS_DATA$RESULT$STATUS != 0) {
                        stop(GET_STATS_DATA$RESULT$ERROR_MSG)
                      }

                      total <- GET_STATS_DATA$STATISTICAL_DATA$RESULT_INF$TOTAL_NUMBER

                      # key
                      key <- list(self$key, names(self$key)) %>%
                        pmap_df(~ .x %>%
                                  mutate(col_name = .y))

                      # get data
                      self$data <- seq(1, total, limit) %>%
                        map_df(function(startPosition) {

                          endPosition <- format(startPosition + limit - 1,
                                                scientific = F)
                          str_glue("Downloading data from lines {startPosition} to {endPosition}") %>%
                            print()

                          Sys.sleep(1)
                          GET_STATS_DATA <- GET(url = self$url,
                                                query = query %>%
                                                  c(list(startPosition = format(startPosition,
                                                                                scientific = F),
                                                         limit = format(limit,
                                                                        scientific = F)))) %>%
                            content() %>%
                            pluck("GET_STATS_DATA")

                          if (GET_STATS_DATA$RESULT$STATUS != 0) {
                            stop(GET_STATS_DATA$RESULT$ERROR_MSG)
                          }

                          DATA_INF <- GET_STATS_DATA$STATISTICAL_DATA$DATA_INF

                          if (startPosition == 1) {
                            self$note <- DATA_INF$NOTE %>%
                              enframe() %>%
                              mutate(value = value %>%
                                       map_chr(. %>%
                                                 str_c(collapse = "_")))
                          }

                          VALUE <- DATA_INF$VALUE %>%
                            bind_rows() %>%
                            rename(value = `$`) %>%
                            rename_with(. %>%
                                          str_remove("^@") %>%
                                          str_replace_all(private$key_name %>%
                                                            set_names(private$key_id))) %>%
                            mutate(value = parse_number(value)) %>%
                            left_join(self$value %>%
                                        select(code, name),
                                      by = c("tab" = "code")) %>%
                            select(-tab) %>%
                            replace_na(list(unit = "")) %>%
                            pivot_wider(names_from = c(name, unit),
                                        names_glue = '{name}{dplyr::if_else(unit == "", "", "_")}{unit}',
                                        values_from = value) %>%
                            rowid_to_column()

                          VALUE %>%
                            select(rowid, all_of(private$key_name)) %>%
                            pivot_longer(-rowid,
                                         names_to = "col_name",
                                         values_to = "code") %>%
                            left_join(key,
                                      by = c("col_name", "code")) %>%
                            pivot_wider(names_from = col_name,
                                        values_from = -c(rowid, col_name)) %>%
                            select(-where(~ all(is.na(.)))) %>%
                            left_join(VALUE %>%
                                        select(-all_of(private$key_name)),
                                      by = "rowid") %>%
                            select(-rowid)
                        })

                      self$data
                    },
                    restore_key = function() {
                      self$key <- private$key_raw
                    },
                    restore_value = function() {
                      self$value <- private$value_raw
                    }
                  ),
                  private = list(
                    key_id = NULL,
                    key_name = NULL,
                    key_raw = NULL,
                    value_raw = NULL
                  ))
