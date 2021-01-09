get_appId <- function() {
  if (nrow(keyring::key_list(service = "e-Stat-appId")) == 0) {
    skip('Set the appId  by keyring::key_set("e-Stat-appId")')
  }

  keyring::key_get("e-Stat-appId")
}

test_that("", {
  appId <- get_appId()

  e_stat_ <- e_stat$new("0003413193", appId)

  .e_stat$key[[stringi::stri_unescape_unicode("\\u79fb\\u52d5\\u5f8c\\u306e\\u4f4f\\u6240\\u5730(\\u73fe\\u4f4f\\u5730)2019\\uff5e")]] %<>%
    filter(name == stringi::stri_unescape_unicode("\\u5317\\u6d77\\u9053"))
  .e_stat$key[[stringi::stri_unescape_unicode("\\u56fd\\u7c4d")]] %<>%
    filter(name == stringi::stri_unescape_unicode("\\u79fb\\u52d5\\u8005"))
  .e_stat$key[[stringi::stri_unescape_unicode("\\u79fb\\u52d5\\u524d\\u306e\\u4f4f\\u6240\\u5730(\\u524d\\u4f4f\\u5730)2019\\uff5e")]] %<>%
    filter(name == stringi::stri_unescape_unicode("\\u7dcf\\u6570\\uff08\\u524d\\u4f4f\\u5730\\uff09"))
  .e_stat_data <- .e_stat$get_data()
  expect_s3_class(.e_stat_data, "data.frame")
})
