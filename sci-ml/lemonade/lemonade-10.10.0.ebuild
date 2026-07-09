# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# awk -F\" '/resolved/ {printf("\t\"%s\"\n",substr($4,28))}' src/web-app/package-lock.json | sort
NPM_MODULES=(
	"acorn/-/acorn-8.16.0.tgz"
	"acorn-import-phases/-/acorn-import-phases-1.0.4.tgz"
	"ajv/-/ajv-8.18.0.tgz"
	"ajv-formats/-/ajv-formats-2.1.1.tgz"
	"ajv-keywords/-/ajv-keywords-5.1.0.tgz"
	"ansi-regex/-/ansi-regex-5.0.1.tgz"
	"ansi-styles/-/ansi-styles-4.3.0.tgz"
	"argparse/-/argparse-2.0.1.tgz"
	"asynckit/-/asynckit-0.4.0.tgz"
	"axios/-/axios-1.15.0.tgz"
	"baseline-browser-mapping/-/baseline-browser-mapping-2.10.19.tgz"
	"boolbase/-/boolbase-1.0.0.tgz"
	"braces/-/braces-3.0.3.tgz"
	"browserslist/-/browserslist-4.28.2.tgz"
	"buffer-from/-/buffer-from-1.1.2.tgz"
	"call-bind-apply-helpers/-/call-bind-apply-helpers-1.0.2.tgz"
	"camel-case/-/camel-case-4.1.2.tgz"
	"caniuse-lite/-/caniuse-lite-1.0.30001788.tgz"
	"chalk/-/chalk-4.1.2.tgz"
	"chrome-trace-event/-/chrome-trace-event-1.0.4.tgz"
	"clean-css/-/clean-css-5.3.3.tgz"
	"clone-deep/-/clone-deep-4.0.1.tgz"
	"color-convert/-/color-convert-2.0.1.tgz"
	"colorette/-/colorette-2.0.20.tgz"
	"color-name/-/color-name-1.1.4.tgz"
	"combined-stream/-/combined-stream-1.0.8.tgz"
	"commander/-/commander-12.1.0.tgz"
	"commander/-/commander-2.20.3.tgz"
	"commander/-/commander-8.3.0.tgz"
	"cross-spawn/-/cross-spawn-7.0.6.tgz"
	"cssesc/-/cssesc-3.0.0.tgz"
	"css-loader/-/css-loader-7.1.4.tgz"
	"css-select/-/css-select-4.3.0.tgz"
	"csstype/-/csstype-3.2.3.tgz"
	"css-what/-/css-what-6.2.2.tgz"
	"delayed-stream/-/delayed-stream-1.0.0.tgz"
	"@discoveryjs/json-ext/-/json-ext-0.6.3.tgz"
	"dom-converter/-/dom-converter-0.2.0.tgz"
	"domelementtype/-/domelementtype-2.3.0.tgz"
	"domhandler/-/domhandler-4.3.1.tgz"
	"dom-serializer/-/dom-serializer-1.4.1.tgz"
	"domutils/-/domutils-2.8.0.tgz"
	"dot-case/-/dot-case-3.0.4.tgz"
	"dunder-proto/-/dunder-proto-1.0.1.tgz"
	"electron-to-chromium/-/electron-to-chromium-1.5.340.tgz"
	"enhanced-resolve/-/enhanced-resolve-5.20.1.tgz"
	"entities/-/entities-2.2.0.tgz"
	"entities/-/entities-2.2.0.tgz"
	"entities/-/entities-4.5.0.tgz"
	"envinfo/-/envinfo-7.21.0.tgz"
	"escalade/-/escalade-3.2.0.tgz"
	"es-define-property/-/es-define-property-1.0.1.tgz"
	"es-errors/-/es-errors-1.3.0.tgz"
	"eslint-scope/-/eslint-scope-5.1.1.tgz"
	"es-module-lexer/-/es-module-lexer-2.0.0.tgz"
	"es-object-atoms/-/es-object-atoms-1.1.1.tgz"
	"esrecurse/-/esrecurse-4.3.0.tgz"
	"es-set-tostringtag/-/es-set-tostringtag-2.1.0.tgz"
	"estraverse/-/estraverse-4.3.0.tgz"
	"estraverse/-/estraverse-5.3.0.tgz"
	"events/-/events-3.3.0.tgz"
	"fast-deep-equal/-/fast-deep-equal-3.1.3.tgz"
	"fastest-levenshtein/-/fastest-levenshtein-1.0.16.tgz"
	"fast-uri/-/fast-uri-3.1.0.tgz"
	"fill-range/-/fill-range-7.1.1.tgz"
	"find-up/-/find-up-4.1.0.tgz"
	"flat/-/flat-5.0.2.tgz"
	"follow-redirects/-/follow-redirects-1.16.0.tgz"
	"form-data/-/form-data-4.0.5.tgz"
	"function-bind/-/function-bind-1.1.2.tgz"
	"get-intrinsic/-/get-intrinsic-1.3.0.tgz"
	"get-proto/-/get-proto-1.0.1.tgz"
	"glob-to-regexp/-/glob-to-regexp-0.4.1.tgz"
	"gopd/-/gopd-1.2.0.tgz"
	"graceful-fs/-/graceful-fs-4.2.11.tgz"
	"has-flag/-/has-flag-4.0.0.tgz"
	"hasown/-/hasown-2.0.2.tgz"
	"has-symbols/-/has-symbols-1.1.0.tgz"
	"has-tostringtag/-/has-tostringtag-1.0.2.tgz"
	"he/-/he-1.2.0.tgz"
	"highlight.js/-/highlight.js-11.11.1.tgz"
	"html-minifier-terser/-/html-minifier-terser-6.1.0.tgz"
	"htmlparser2/-/htmlparser2-6.1.0.tgz"
	"html-webpack-plugin/-/html-webpack-plugin-5.6.7.tgz"
	"icss-utils/-/icss-utils-5.1.0.tgz"
	"import-local/-/import-local-3.2.0.tgz"
	"interpret/-/interpret-3.1.1.tgz"
	"is-core-module/-/is-core-module-2.16.1.tgz"
	"isexe/-/isexe-2.0.0.tgz"
	"is-number/-/is-number-7.0.0.tgz"
	"isobject/-/isobject-3.0.1.tgz"
	"is-plain-object/-/is-plain-object-2.0.4.tgz"
	"jest-worker/-/jest-worker-27.5.1.tgz"
	"@jridgewell/gen-mapping/-/gen-mapping-0.3.13.tgz"
	"@jridgewell/resolve-uri/-/resolve-uri-3.1.2.tgz"
	"@jridgewell/sourcemap-codec/-/sourcemap-codec-1.5.5.tgz"
	"@jridgewell/source-map/-/source-map-0.3.11.tgz"
	"@jridgewell/trace-mapping/-/trace-mapping-0.3.31.tgz"
	"json-schema-traverse/-/json-schema-traverse-1.0.0.tgz"
	"katex/-/katex-0.16.45.tgz"
	"kind-of/-/kind-of-6.0.3.tgz"
	"linkify-it/-/linkify-it-5.0.0.tgz"
	"loader-runner/-/loader-runner-4.3.1.tgz"
	"locate-path/-/locate-path-5.0.0.tgz"
	"lodash/-/lodash-4.17.23.tgz"
	"lower-case/-/lower-case-2.0.2.tgz"
	"markdown-it/-/markdown-it-14.1.1.tgz"
	"markdown-it-texmath/-/markdown-it-texmath-1.0.0.tgz"
	"math-intrinsics/-/math-intrinsics-1.1.0.tgz"
	"mdurl/-/mdurl-2.0.0.tgz"
	"merge-stream/-/merge-stream-2.0.0.tgz"
	"micromatch/-/micromatch-4.0.8.tgz"
	"mime-db/-/mime-db-1.52.0.tgz"
	"mime-db/-/mime-db-1.54.0.tgz"
	"mime-types/-/mime-types-2.1.35.tgz"
	"nanoid/-/nanoid-3.3.11.tgz"
	"neo-async/-/neo-async-2.6.2.tgz"
	"no-case/-/no-case-3.0.4.tgz"
	"node-releases/-/node-releases-2.0.37.tgz"
	"nth-check/-/nth-check-2.1.1.tgz"
	"param-case/-/param-case-3.0.4.tgz"
	"pascal-case/-/pascal-case-3.1.2.tgz"
	"path-exists/-/path-exists-4.0.0.tgz"
	"path-key/-/path-key-3.1.1.tgz"
	"path-parse/-/path-parse-1.0.7.tgz"
	"picocolors/-/picocolors-1.1.1.tgz"
	"picomatch/-/picomatch-2.3.2.tgz"
	"pkg-dir/-/pkg-dir-4.2.0.tgz"
	"p-limit/-/p-limit-2.3.0.tgz"
	"p-locate/-/p-locate-4.1.0.tgz"
	"postcss-modules-extract-imports/-/postcss-modules-extract-imports-3.1.0.tgz"
	"postcss-modules-local-by-default/-/postcss-modules-local-by-default-4.2.0.tgz"
	"postcss-modules-scope/-/postcss-modules-scope-3.2.1.tgz"
	"postcss-modules-values/-/postcss-modules-values-4.0.0.tgz"
	"postcss/-/postcss-8.5.10.tgz"
	"postcss-selector-parser/-/postcss-selector-parser-7.1.1.tgz"
	"postcss-value-parser/-/postcss-value-parser-4.2.0.tgz"
	"pretty-error/-/pretty-error-4.0.0.tgz"
	"proxy-from-env/-/proxy-from-env-2.1.0.tgz"
	"p-try/-/p-try-2.2.0.tgz"
	"punycode.js/-/punycode.js-2.3.1.tgz"
	"react-dom/-/react-dom-19.2.5.tgz"
	"react/-/react-19.2.5.tgz"
	"rechoir/-/rechoir-0.8.0.tgz"
	"relateurl/-/relateurl-0.2.7.tgz"
	"renderkid/-/renderkid-3.0.0.tgz"
	"require-from-string/-/require-from-string-2.0.2.tgz"
	"resolve-cwd/-/resolve-cwd-3.0.0.tgz"
	"resolve-from/-/resolve-from-5.0.0.tgz"
	"resolve/-/resolve-1.22.12.tgz"
	"scheduler/-/scheduler-0.27.0.tgz"
	"schema-utils/-/schema-utils-4.3.3.tgz"
	"semver/-/semver-7.7.4.tgz"
	"shallow-clone/-/shallow-clone-3.0.1.tgz"
	"shebang-command/-/shebang-command-2.0.0.tgz"
	"shebang-regex/-/shebang-regex-3.0.0.tgz"
	"source-map-js/-/source-map-js-1.2.1.tgz"
	"source-map/-/source-map-0.6.1.tgz"
	"source-map/-/source-map-0.7.6.tgz"
	"source-map-support/-/source-map-support-0.5.21.tgz"
	"strip-ansi/-/strip-ansi-6.0.1.tgz"
	"style-loader/-/style-loader-4.0.0.tgz"
	"supports-color/-/supports-color-7.2.0.tgz"
	"supports-color/-/supports-color-8.1.1.tgz"
	"supports-preserve-symlinks-flag/-/supports-preserve-symlinks-flag-1.0.0.tgz"
	"tapable/-/tapable-2.3.2.tgz"
	"terser/-/terser-5.46.1.tgz"
	"terser-webpack-plugin/-/terser-webpack-plugin-5.4.0.tgz"
	"to-regex-range/-/to-regex-range-5.0.1.tgz"
	"tslib/-/tslib-2.8.1.tgz"
	"ts-loader/-/ts-loader-9.5.7.tgz"
	"typescript/-/typescript-5.9.3.tgz"
	"@types/eslint/-/eslint-9.6.1.tgz"
	"@types/eslint-scope/-/eslint-scope-3.7.7.tgz"
	"@types/estree/-/estree-1.0.8.tgz"
	"@types/html-minifier-terser/-/html-minifier-terser-6.1.0.tgz"
	"@types/json-schema/-/json-schema-7.0.15.tgz"
	"@types/katex/-/katex-0.16.8.tgz"
	"@types/linkify-it/-/linkify-it-5.0.0.tgz"
	"@types/markdown-it/-/markdown-it-14.1.2.tgz"
	"@types/mdurl/-/mdurl-2.0.0.tgz"
	"@types/node/-/node-25.6.0.tgz"
	"@types/react-dom/-/react-dom-19.2.3.tgz"
	"@types/react/-/react-19.2.14.tgz"
	"uc.micro/-/uc.micro-2.1.0.tgz"
	"undici-types/-/undici-types-7.19.2.tgz"
	"update-browserslist-db/-/update-browserslist-db-1.2.3.tgz"
	"utila/-/utila-0.4.0.tgz"
	"util-deprecate/-/util-deprecate-1.0.2.tgz"
	"watchpack/-/watchpack-2.5.1.tgz"
	"@webassemblyjs/ast/-/ast-1.14.1.tgz"
	"@webassemblyjs/floating-point-hex-parser/-/floating-point-hex-parser-1.13.2.tgz"
	"@webassemblyjs/helper-api-error/-/helper-api-error-1.13.2.tgz"
	"@webassemblyjs/helper-buffer/-/helper-buffer-1.14.1.tgz"
	"@webassemblyjs/helper-numbers/-/helper-numbers-1.13.2.tgz"
	"@webassemblyjs/helper-wasm-bytecode/-/helper-wasm-bytecode-1.13.2.tgz"
	"@webassemblyjs/helper-wasm-section/-/helper-wasm-section-1.14.1.tgz"
	"@webassemblyjs/ieee754/-/ieee754-1.13.2.tgz"
	"@webassemblyjs/leb128/-/leb128-1.13.2.tgz"
	"@webassemblyjs/utf8/-/utf8-1.13.2.tgz"
	"@webassemblyjs/wasm-edit/-/wasm-edit-1.14.1.tgz"
	"@webassemblyjs/wasm-gen/-/wasm-gen-1.14.1.tgz"
	"@webassemblyjs/wasm-opt/-/wasm-opt-1.14.1.tgz"
	"@webassemblyjs/wasm-parser/-/wasm-parser-1.14.1.tgz"
	"@webassemblyjs/wast-printer/-/wast-printer-1.14.1.tgz"
	"@webpack-cli/configtest/-/configtest-3.0.1.tgz"
	"@webpack-cli/info/-/info-3.0.1.tgz"
	"@webpack-cli/serve/-/serve-3.0.1.tgz"
	"webpack-cli/-/webpack-cli-6.0.1.tgz"
	"webpack-merge/-/webpack-merge-6.0.1.tgz"
	"webpack-sources/-/webpack-sources-3.3.4.tgz"
	"webpack/-/webpack-5.106.2.tgz"
	"which/-/which-2.0.2.tgz"
	"wildcard/-/wildcard-2.0.1.tgz"
	"@xtuc/ieee754/-/ieee754-1.2.0.tgz"
	"@xtuc/long/-/long-4.2.2.tgz"
)

inherit cmake

DESCRIPTION="Local AI server: optimized LLM inference on AMD NPU + GPU"
HOMEPAGE="
	https://lemonade-server.ai/
	https://github.com/lemonade-sdk/lemonade
"

SRC_URI="
	https://github.com/lemonade-sdk/${PN}/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
"
LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64"
IUSE="systemd +webapp"
RESTRICT="mirror"

RDEPEND="
	>=app-arch/zstd-1.5.5
	>=dev-cpp/cpp-httplib-0.26.0
	>=net-libs/libwebsockets-4.3.3
	net-libs/mbedtls:3
	>=net-misc/curl-8.5.0
	sys-libs/libcap
	systemd? (
		acct-group/lemonade
		acct-user/lemonade
		sys-apps/systemd:=
	)
"
DEPEND="${RDEPEND}"
BDEPEND="
	>=dev-cpp/cli11-2.4.2
	>=dev-cpp/nlohmann_json-3.11.3
	x11-libs/libdrm
	virtual/pkgconfig
	webapp? (
		net-libs/nodejs[npm]
	)
"

add_npm_modules() {
	local module=${1}

	SRC_URI+="webapp? (
		$(for module; do
			echo "https://registry.npmjs.org/${module} -> npm-${module%%/*}-${module##*/}"
		done)
	)"
}

add_npm_modules "${NPM_MODULES[@]}"

src_unpack() {
	unpack ${P}.tar.gz || die

	local -a myopts=(
		--audit=false
		--color=false
		--foreground-scripts
		--offline
		--progress=false
		--save=false
		--verbose
    )

	if use webapp; then
		cd "${S}/src/web-app" || die
		sed -e "s|https://registry.npmjs.org/\([^/]*\)/.*/\(.*\)$|file://${DISTDIR}/npm-\1-\2|" \
			-i package-lock.json || die
		npm "${myopts[@]}" install || die
	fi
}

src_prepare() {
	cmake_src_prepare

	if ! use systemd; then
		# Prevent linking against libsystemd (journal support)
		sed -e '/pkg_check_modules(SYSTEMD QUIET libsystemd)/d' \
			-i CMakeLists.txt || die
	fi
}

src_configure() {
	local mycmakeargs=(
		-DBUILD_WEB_APP=$(usex webapp ON OFF)
		-DBUILD_TAURI_APP=OFF
		# Workaround for missing cpp-httplib pkgconfig support
		-DUSE_SYSTEM_HTTPLIB=ON
		-DHTTPLIB_LINK_LIBRARIES=cpp-httplib
		# We have mbedcrypto-3 instead of mbedcrypto
		-DMBEDTLS_INCLUDE_DIR=/usr/include/mbedtls3
		-DMBEDCRYPTO_LIBRARY=/usr/lib64/libmbedcrypto-3.so
	)
	cmake_src_configure
}

src_install() {
	cmake_src_install

	if ! use systemd; then
		rm -f "${ED}"/usr/lib/systemd/{system,user}/lemond.service
		rmdir -p "${ED}"/usr/lib/systemd/{system,user} 2>/dev/null
	fi
}
