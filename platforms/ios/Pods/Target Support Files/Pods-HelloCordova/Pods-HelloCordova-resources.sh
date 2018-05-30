#!/bin/sh
set -e
set -u
set -o pipefail

if [ -z ${UNLOCALIZED_RESOURCES_FOLDER_PATH+x} ]; then
    # If UNLOCALIZED_RESOURCES_FOLDER_PATH is not set, then there's nowhere for us to copy
    # resources to, so exit 0 (signalling the script phase was successful).
    exit 0
fi

mkdir -p "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"

RESOURCES_TO_COPY=${PODS_ROOT}/resources-to-copy-${TARGETNAME}.txt
> "$RESOURCES_TO_COPY"

XCASSET_FILES=()

# This protects against multiple targets copying the same framework dependency at the same time. The solution
# was originally proposed here: https://lists.samba.org/archive/rsync/2008-February/020158.html
RSYNC_PROTECT_TMP_FILES=(--filter "P .*.??????")

case "${TARGETED_DEVICE_FAMILY:-}" in
  1,2)
    TARGET_DEVICE_ARGS="--target-device ipad --target-device iphone"
    ;;
  1)
    TARGET_DEVICE_ARGS="--target-device iphone"
    ;;
  2)
    TARGET_DEVICE_ARGS="--target-device ipad"
    ;;
  3)
    TARGET_DEVICE_ARGS="--target-device tv"
    ;;
  4)
    TARGET_DEVICE_ARGS="--target-device watch"
    ;;
  *)
    TARGET_DEVICE_ARGS="--target-device mac"
    ;;
esac

install_resource()
{
  if [[ "$1" = /* ]] ; then
    RESOURCE_PATH="$1"
  else
    RESOURCE_PATH="${PODS_ROOT}/$1"
  fi
  if [[ ! -e "$RESOURCE_PATH" ]] ; then
    cat << EOM
error: Resource "$RESOURCE_PATH" not found. Run 'pod install' to update the copy resources script.
EOM
    exit 1
  fi
  case $RESOURCE_PATH in
    *.storyboard)
      echo "ibtool --reference-external-strings-file --errors --warnings --notices --minimum-deployment-target ${!DEPLOYMENT_TARGET_SETTING_NAME} --output-format human-readable-text --compile ${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename \"$RESOURCE_PATH\" .storyboard`.storyboardc $RESOURCE_PATH --sdk ${SDKROOT} ${TARGET_DEVICE_ARGS}" || true
      ibtool --reference-external-strings-file --errors --warnings --notices --minimum-deployment-target ${!DEPLOYMENT_TARGET_SETTING_NAME} --output-format human-readable-text --compile "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename \"$RESOURCE_PATH\" .storyboard`.storyboardc" "$RESOURCE_PATH" --sdk "${SDKROOT}" ${TARGET_DEVICE_ARGS}
      ;;
    *.xib)
      echo "ibtool --reference-external-strings-file --errors --warnings --notices --minimum-deployment-target ${!DEPLOYMENT_TARGET_SETTING_NAME} --output-format human-readable-text --compile ${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename \"$RESOURCE_PATH\" .xib`.nib $RESOURCE_PATH --sdk ${SDKROOT} ${TARGET_DEVICE_ARGS}" || true
      ibtool --reference-external-strings-file --errors --warnings --notices --minimum-deployment-target ${!DEPLOYMENT_TARGET_SETTING_NAME} --output-format human-readable-text --compile "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename \"$RESOURCE_PATH\" .xib`.nib" "$RESOURCE_PATH" --sdk "${SDKROOT}" ${TARGET_DEVICE_ARGS}
      ;;
    *.framework)
      echo "mkdir -p ${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}" || true
      mkdir -p "${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
      echo "rsync --delete -av "${RSYNC_PROTECT_TMP_FILES[@]}" $RESOURCE_PATH ${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}" || true
      rsync --delete -av "${RSYNC_PROTECT_TMP_FILES[@]}" "$RESOURCE_PATH" "${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
      ;;
    *.xcdatamodel)
      echo "xcrun momc \"$RESOURCE_PATH\" \"${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$RESOURCE_PATH"`.mom\"" || true
      xcrun momc "$RESOURCE_PATH" "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$RESOURCE_PATH" .xcdatamodel`.mom"
      ;;
    *.xcdatamodeld)
      echo "xcrun momc \"$RESOURCE_PATH\" \"${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$RESOURCE_PATH" .xcdatamodeld`.momd\"" || true
      xcrun momc "$RESOURCE_PATH" "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$RESOURCE_PATH" .xcdatamodeld`.momd"
      ;;
    *.xcmappingmodel)
      echo "xcrun mapc \"$RESOURCE_PATH\" \"${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$RESOURCE_PATH" .xcmappingmodel`.cdm\"" || true
      xcrun mapc "$RESOURCE_PATH" "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$RESOURCE_PATH" .xcmappingmodel`.cdm"
      ;;
    *.xcassets)
      ABSOLUTE_XCASSET_FILE="$RESOURCE_PATH"
      XCASSET_FILES+=("$ABSOLUTE_XCASSET_FILE")
      ;;
    *)
      echo "$RESOURCE_PATH" || true
      echo "$RESOURCE_PATH" >> "$RESOURCES_TO_COPY"
      ;;
  esac
}
if [[ "$CONFIGURATION" == "Debug" ]]; then
  install_resource "${PODS_ROOT}/FBSDKCoreKit/FacebookSDKStrings.bundle"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/pduikit_brand_placeholder.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/pduikit_cancelbutton.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/pduikit_cancelbutton@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/pduikit_cancelbutton@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/pduikit_default_login.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/pduikit_default_login@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/pduikit_default_login@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/pduikit_instagramstep1.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/pduikit_instagramstep2.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/pduikit_popdeemArrowB.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/pduikit_popdeemArrowB@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/pduikit_popdeemArrowB@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/BrandList/PDUIBrandPlaceHolderTableViewCell.xib"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/BrandList/PDUIBrandSearchTableViewCell.xib"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/BrandList/PDUIBrandsListTableViewController.xib"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/BrandList/PDUIBrandTableViewCell.xib"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Claim/PDUIClaimViewController.xib"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Claim/Post Scan Failure/PDUIScanFailViewController.xib"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Claim/Post Scan/PDUIPostScanViewController.xib"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Claim/Scan/PDUIInstagramScanViewController.xib"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Claim/Scan/PDUIScanViewController.xib"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Claim/Select Network/PDUISelectNetworkViewController.xib"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Facebook/Login/PDUIFBLoginWithWritePermsViewController.xib"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Friend Picker/PDUIFriendPickerViewController.xib"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Gratutude/PDUIGratitudeViewController.xib"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Home/Cells/No Rewards/PDUINoRewardTableViewCell.xib"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Home/Cells/Profile/PDUIProfileButtonTableViewCell.xib"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Home/Cells/Profile/ProfileTableViewCell.xib"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Home/Cells/Rewards/PDUIRewardWithRulesTableViewCell.xib"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Home/Cells/Rewards/V2/PDUIRewardV2TableViewCell.xib"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Home/Cells/Wallet/PDUIInstagramUnverifiedWalletTableViewCell.xib"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Home/Cells/Wallet/PDUITierEventTableViewCell.xib"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Home/Cells/Wallet/PDUIWalletRewardTableViewCell.xib"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Home/PDUIHomeViewController.xib"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Instagram/PDUIInstagramWebViewController.xib"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Login/MultiLogin/PDMultiLoginViewController.xib"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Login/PDUISocialLoginViewController.xib"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/MessageCenter/PDUIMessageCell.xib"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/MessageCenter/PDUIMsgCntrTblViewController.xib"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/MessageCenter/PDUISingleMessageViewController.xib"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Placeholder/PlaceholderTableViewCell.xib"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/ambassador_icon_default.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/ambassador_icon_default@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/ambassador_icon_default@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/bluePopdeemHeader.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/bluePopdeemHeader@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/bluePopdeemHeader@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/default.json"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/default_theme.json"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit-branddummycell.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit-branddummycell@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit-branddummycell@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_addFriend.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_addFriend@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_addFriend@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_arrowB.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_arrowB@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_arrowB@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_camera.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_camera@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_camera@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_default_login_blue.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_default_login_blue@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_default_login_blue@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_default_user.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_deselectedCheck.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_deselectedCheck@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_deselectedCheck@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_facebook_hires.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_facebook_hires@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_facebook_hires@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_fbbutton_deselected.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_fbbutton_deselected@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_fbbutton_deselected@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_fbbutton_selected.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_fbbutton_selected@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_fbbutton_selected@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_fb_hi.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_fb_hi@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_fb_hi@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_instagrambutton_deselected.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_instagrambutton_deselected@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_instagrambutton_deselected@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_instagrambutton_selected.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_instagrambutton_selected@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_instagrambutton_selected@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_instagramstep3.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_instagram_hi.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_instagram_hi@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_instagram_hi@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_instagram_hires.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_mail.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_mail@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_mail@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_mailCircle.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_mail_blue.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_placeholder.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_popdeemHeader.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_popdeemHeader@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_popdeemHeader@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_popdeemHeaderLight.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_popdeemHeaderLight@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_popdeemHeaderLight@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_rainbow.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_rainbow@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_rainbow@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_refresh.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_refresh@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_refresh@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_rewardsIcon.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_rewardsIcon@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_rewardsIconSuccess.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_rewardsIconSuccess@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_search.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_selectedCheck.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_selectedCheck@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_selectedCheck@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_settings.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_settings@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_settings@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_starG.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_starG@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_starG@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_tagGoButton.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_tickG.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_tickG@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_tickG@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_tickGrey.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_tickGrey@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_tickGrey@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_twitterbutton_deselected.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_twitterbutton_deselected@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_twitterbutton_deselected@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_twitterbutton_selected.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_twitterbutton_selected@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_twitterbutton_selected@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_x@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_x@3x copy.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_x_icon.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_x_white.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_x_white@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_x_white@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduirewardfacebookicon.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduirewardfacebookicon@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduirewardfacebookicon@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduirewardinstagramicon.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduirewardinstagramicon@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduirewardinstagramicon@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduirewardtwittericon.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduirewardtwittericon@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduirewardtwittericon@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/PDUI_Back.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/PDUI_Back@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/PDUI_Back@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pdui_default_user_image.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pdui_default_user_image@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pdui_default_user_image@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/PDUI_IGBG.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/PDUI_IGBG@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/PDUI_IGBG@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pd_message.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pd_message@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pd_message@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/Twitter_Logo_Blue.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/Twitter_Logo_Blue@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/Twitter_Logo_Blue@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Reward/PDUIRedeemViewController.xib"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Settings/PDUILogoutTableViewCell.xib"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Settings/PDUISettingsViewController.xib"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Settings/PDUISocialSettingsTableViewCell.xib"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Twitter/Login/PDUITwitterLoginViewController.xib"
  install_resource "${PODS_CONFIGURATION_BUILD_DIR}/TOCropViewController/TOCropViewControllerBundle.bundle"
fi
if [[ "$CONFIGURATION" == "Release" ]]; then
  install_resource "${PODS_ROOT}/FBSDKCoreKit/FacebookSDKStrings.bundle"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/pduikit_brand_placeholder.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/pduikit_cancelbutton.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/pduikit_cancelbutton@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/pduikit_cancelbutton@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/pduikit_default_login.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/pduikit_default_login@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/pduikit_default_login@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/pduikit_instagramstep1.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/pduikit_instagramstep2.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/pduikit_popdeemArrowB.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/pduikit_popdeemArrowB@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/pduikit_popdeemArrowB@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/BrandList/PDUIBrandPlaceHolderTableViewCell.xib"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/BrandList/PDUIBrandSearchTableViewCell.xib"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/BrandList/PDUIBrandsListTableViewController.xib"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/BrandList/PDUIBrandTableViewCell.xib"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Claim/PDUIClaimViewController.xib"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Claim/Post Scan Failure/PDUIScanFailViewController.xib"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Claim/Post Scan/PDUIPostScanViewController.xib"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Claim/Scan/PDUIInstagramScanViewController.xib"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Claim/Scan/PDUIScanViewController.xib"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Claim/Select Network/PDUISelectNetworkViewController.xib"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Facebook/Login/PDUIFBLoginWithWritePermsViewController.xib"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Friend Picker/PDUIFriendPickerViewController.xib"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Gratutude/PDUIGratitudeViewController.xib"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Home/Cells/No Rewards/PDUINoRewardTableViewCell.xib"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Home/Cells/Profile/PDUIProfileButtonTableViewCell.xib"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Home/Cells/Profile/ProfileTableViewCell.xib"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Home/Cells/Rewards/PDUIRewardWithRulesTableViewCell.xib"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Home/Cells/Rewards/V2/PDUIRewardV2TableViewCell.xib"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Home/Cells/Wallet/PDUIInstagramUnverifiedWalletTableViewCell.xib"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Home/Cells/Wallet/PDUITierEventTableViewCell.xib"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Home/Cells/Wallet/PDUIWalletRewardTableViewCell.xib"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Home/PDUIHomeViewController.xib"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Instagram/PDUIInstagramWebViewController.xib"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Login/MultiLogin/PDMultiLoginViewController.xib"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Login/PDUISocialLoginViewController.xib"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/MessageCenter/PDUIMessageCell.xib"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/MessageCenter/PDUIMsgCntrTblViewController.xib"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/MessageCenter/PDUISingleMessageViewController.xib"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Placeholder/PlaceholderTableViewCell.xib"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/ambassador_icon_default.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/ambassador_icon_default@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/ambassador_icon_default@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/bluePopdeemHeader.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/bluePopdeemHeader@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/bluePopdeemHeader@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/default.json"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/default_theme.json"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit-branddummycell.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit-branddummycell@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit-branddummycell@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_addFriend.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_addFriend@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_addFriend@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_arrowB.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_arrowB@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_arrowB@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_camera.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_camera@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_camera@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_default_login_blue.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_default_login_blue@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_default_login_blue@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_default_user.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_deselectedCheck.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_deselectedCheck@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_deselectedCheck@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_facebook_hires.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_facebook_hires@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_facebook_hires@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_fbbutton_deselected.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_fbbutton_deselected@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_fbbutton_deselected@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_fbbutton_selected.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_fbbutton_selected@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_fbbutton_selected@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_fb_hi.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_fb_hi@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_fb_hi@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_instagrambutton_deselected.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_instagrambutton_deselected@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_instagrambutton_deselected@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_instagrambutton_selected.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_instagrambutton_selected@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_instagrambutton_selected@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_instagramstep3.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_instagram_hi.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_instagram_hi@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_instagram_hi@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_instagram_hires.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_mail.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_mail@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_mail@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_mailCircle.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_mail_blue.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_placeholder.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_popdeemHeader.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_popdeemHeader@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_popdeemHeader@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_popdeemHeaderLight.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_popdeemHeaderLight@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_popdeemHeaderLight@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_rainbow.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_rainbow@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_rainbow@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_refresh.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_refresh@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_refresh@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_rewardsIcon.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_rewardsIcon@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_rewardsIconSuccess.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_rewardsIconSuccess@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_search.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_selectedCheck.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_selectedCheck@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_selectedCheck@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_settings.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_settings@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_settings@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_starG.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_starG@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_starG@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_tagGoButton.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_tickG.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_tickG@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_tickG@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_tickGrey.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_tickGrey@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_tickGrey@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_twitterbutton_deselected.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_twitterbutton_deselected@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_twitterbutton_deselected@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_twitterbutton_selected.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_twitterbutton_selected@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_twitterbutton_selected@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_x@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_x@3x copy.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_x_icon.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_x_white.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_x_white@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduikit_x_white@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduirewardfacebookicon.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduirewardfacebookicon@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduirewardfacebookicon@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduirewardinstagramicon.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduirewardinstagramicon@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduirewardinstagramicon@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduirewardtwittericon.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduirewardtwittericon@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pduirewardtwittericon@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/PDUI_Back.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/PDUI_Back@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/PDUI_Back@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pdui_default_user_image.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pdui_default_user_image@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pdui_default_user_image@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/PDUI_IGBG.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/PDUI_IGBG@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/PDUI_IGBG@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pd_message.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pd_message@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/pd_message@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/Twitter_Logo_Blue.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/Twitter_Logo_Blue@2x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Resources/Twitter_Logo_Blue@3x.png"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Reward/PDUIRedeemViewController.xib"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Settings/PDUILogoutTableViewCell.xib"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Settings/PDUISettingsViewController.xib"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Settings/PDUISocialSettingsTableViewCell.xib"
  install_resource "${PODS_ROOT}/PopdeemSDK/PopdeemSDK/UIKit/Twitter/Login/PDUITwitterLoginViewController.xib"
  install_resource "${PODS_CONFIGURATION_BUILD_DIR}/TOCropViewController/TOCropViewControllerBundle.bundle"
fi

mkdir -p "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
rsync -avr --copy-links --no-relative --exclude '*/.svn/*' --files-from="$RESOURCES_TO_COPY" / "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
if [[ "${ACTION}" == "install" ]] && [[ "${SKIP_INSTALL}" == "NO" ]]; then
  mkdir -p "${INSTALL_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
  rsync -avr --copy-links --no-relative --exclude '*/.svn/*' --files-from="$RESOURCES_TO_COPY" / "${INSTALL_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
fi
rm -f "$RESOURCES_TO_COPY"

if [[ -n "${WRAPPER_EXTENSION}" ]] && [ "`xcrun --find actool`" ] && [ -n "${XCASSET_FILES:-}" ]
then
  # Find all other xcassets (this unfortunately includes those of path pods and other targets).
  OTHER_XCASSETS=$(find "$PWD" -iname "*.xcassets" -type d)
  while read line; do
    if [[ $line != "${PODS_ROOT}*" ]]; then
      XCASSET_FILES+=("$line")
    fi
  done <<<"$OTHER_XCASSETS"

  if [ -z ${ASSETCATALOG_COMPILER_APPICON_NAME+x} ]; then
    printf "%s\0" "${XCASSET_FILES[@]}" | xargs -0 xcrun actool --output-format human-readable-text --notices --warnings --platform "${PLATFORM_NAME}" --minimum-deployment-target "${!DEPLOYMENT_TARGET_SETTING_NAME}" ${TARGET_DEVICE_ARGS} --compress-pngs --compile "${BUILT_PRODUCTS_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
  else
    printf "%s\0" "${XCASSET_FILES[@]}" | xargs -0 xcrun actool --output-format human-readable-text --notices --warnings --platform "${PLATFORM_NAME}" --minimum-deployment-target "${!DEPLOYMENT_TARGET_SETTING_NAME}" ${TARGET_DEVICE_ARGS} --compress-pngs --compile "${BUILT_PRODUCTS_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}" --app-icon "${ASSETCATALOG_COMPILER_APPICON_NAME}" --output-partial-info-plist "${TARGET_BUILD_DIR}/assetcatalog_generated_info.plist"
  fi
fi
