get_appId <- function() {
  if (nrow(key_list(service = "e-Stat-appId")) == 0) {
    skip('Set the appId  by keyring::key_set("e-Stat-appId")')
  }

  key_get("e-Stat-appId")
}

test_that("", {
  appId <- get_appId()

  .e_stat <- e_stat$new(statsDataId = ,
                        appId = appId)
  .e_stat$key$`移動後の住所地(現住地)2019～` %<>%
    filter(name == "北海道")
  .e_stat$key$国籍 %<>%
    filter(name == "移動者")
  .e_stat$key$`移動前の住所地(前住地)2019～` %<>%
    filter(name == "総数（前住地）")

  .e_stat_data <- .e_stat$get_data()
  expect_s3_class(.e_stat_data, "data.frame")
})
