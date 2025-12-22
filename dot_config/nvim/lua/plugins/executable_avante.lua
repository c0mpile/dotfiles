return {
	{
		"yetone/avante.nvim",
		event = "VeryLazy",
		lazy = false,
		version = false,

		-- KEYS: Added <leader>ab for Balance and <leader>am for Model Select
		keys = {
			{
				"<leader>aa",
				function()
					require("avante.api").ask()
				end,
				desc = "Avante: Ask AI",
				mode = { "n", "v" },
			},
			{ "<leader>aH", "<cmd>AvanteClear<cr>", desc = "Avante: Clear Chat", mode = { "n", "v" } },
			{ "<leader>at", "<cmd>AvanteToggle<cr>", desc = "Avante: Toggle Window", mode = { "n", "v" } },
			{ "<C-\\>", "<cmd>AvanteToggle<cr>", desc = "Avante: Toggle Window", mode = { "n", "v", "i" } },
			{ "<leader>am", "<cmd>AvanteSelectModel<cr>", desc = "Avante: Switch Model", mode = { "n", "v" } },
			{ "<leader>ab", "<cmd>AvanteBalance<cr>", desc = "Avante: Balance", mode = { "n", "v" } },
			{
				"<leader>aW",
				function()
					-- Delete the cache directory
					local cache_dir = vim.fn.stdpath("state") .. "/avante"
					vim.fn.delete(cache_dir, "rf")
					vim.notify("🗑️ Avante cache & history wiped!", vim.log.levels.INFO)
					-- Optional: Clear the current chat view too
					vim.cmd("AvanteClear")
				end,
				desc = "Avante: Wipe History & Cache",
				mode = { "n" },
			},
		},

		init = function()
			-- COMMAND 1: OpenRouter (Session Only)
			vim.api.nvim_create_user_command("AvanteAdd", function(args)
				local model_id = args.args
				local short_key = model_id:match(".*/(.*)") or model_id
				local new_provider = {
					__inherited_from = "openai",
					endpoint = "https://openrouter.ai/api/v1",
					api_key_name = "OPENROUTER_API_KEY",
					model = model_id,
					max_tokens = 4096,
				}
				local config = require("avante.config")
				config.providers[short_key] = new_provider
				config.provider = short_key
				print("🚀 Active (Session): " .. short_key)
			end, { nargs = 1, desc = "Add OpenRouter model for this session" })

			-- COMMAND 2: Ollama (Session Only)
			vim.api.nvim_create_user_command("AvanteAddLocal", function(args)
				local model_id = args.args
				local key_name = "Local-" .. model_id
				local new_provider = {
					__inherited_from = "openai",
					endpoint = "http://127.0.0.1:11434/v1",
					api_key_name = "CMD_RUNNER",
					model = model_id,
					max_tokens = 4096,
				}
				local config = require("avante.config")
				config.providers[key_name] = new_provider
				config.provider = key_name
				print("🚀 Active Ollama: " .. key_name)
			end, { nargs = 1, desc = "Add Ollama model for this session" })

			-- COMMAND 3: LM Studio (Session Only)
			vim.api.nvim_create_user_command("AvanteAddLMStudio", function(args)
				local model_id = args.args
				local key_name = "LMStudio-" .. model_id
				local new_provider = {
					__inherited_from = "openai",
					endpoint = "http://127.0.0.1:1234/v1",
					api_key_name = "CMD_RUNNER",
					model = model_id,
					max_tokens = 4096,
				}
				local config = require("avante.config")
				config.providers[key_name] = new_provider
				config.provider = key_name
				print("🚀 Active LM Studio: " .. key_name)
			end, { nargs = 1, desc = "Add LM Studio model for this session" })

			-- COMMAND 4: Check OpenRouter Credits
			vim.api.nvim_create_user_command("AvanteBalance", function()
				local api_key = os.getenv("OPENROUTER_API_KEY")
				if not api_key then
					vim.notify("❌ OPENROUTER_API_KEY is not set.", vim.log.levels.ERROR)
					return
				end

				local cmd = "curl -s -H 'Authorization: Bearer " .. api_key .. "' https://openrouter.ai/api/v1/credits"
				local handle = io.popen(cmd)
				if not handle then
					return
				end
				local result = handle:read("*a")
				handle:close()

				local ok, json = pcall(vim.json.decode, result)
				if ok and json and json.data then
					local total = json.data.total_credits or 0
					local used = json.data.total_usage or 0
					local remaining = total - used
					local msg = string.format(
						"💰 OpenRouter Balance\n----------------------\nRemaining: $%.4f\nTotal Credit: $%.4f\nTotal Used:   $%.4f",
						remaining,
						total,
						used
					)
					vim.notify(msg, vim.log.levels.INFO)
				else
					vim.notify("❌ Failed to fetch balance.", vim.log.levels.ERROR)
				end
			end, { desc = "Check OpenRouter credit balance" })

			-- COMMAND 5: Switch Model (Cleaner UI)
			vim.api.nvim_create_user_command("AvanteSelectModel", function()
				local config = require("avante.config")
				local providers = {}

				-- The list of specific models you added manually
				local my_models = {
					["GPT-120b"] = true,
					["Qwen3-Coder"] = true,
					["Deepseek-R1t2"] = true,
					["Deepseek-R1-0528"] = true,
					["Deepseek-R1t"] = true,
					["GPT-OSS-20b"] = true,
					["Llama-3.3-70b"] = true,
					["Devstral-2512"] = true,
					["Kimi-k2"] = true,
					["Gemini-2.0-Flash"] = true,
				}

				-- Only add providers if they are in your "allow list"
				for name, _ in pairs(config.providers) do
					if my_models[name] then
						table.insert(providers, name)
					end
				end
				table.sort(providers)

				-- Show the menu
				vim.ui.select(providers, { prompt = "Select Avante Model:" }, function(choice)
					if choice then
						vim.cmd("AvanteSwitchProvider " .. choice)
						vim.notify("✅ Switched to: " .. choice)
					end
				end)
			end, { desc = "Select Avante model from a menu" })
		end,

		opts = function(_, opts)
			opts.providers = opts.providers or {}

			-- HIDE DEFAULTS
			local hidden_models = { "gemini", "vertex", "vertex_claude", "copilot", "azure" }
			for _, name in ipairs(hidden_models) do
				opts.providers[name] = {
					hide_in_model_selector = true,
					model = "hidden",
				}
			end

			-- STATIC PROVIDERS
			opts.providers["GPT-120b"] = {
				__inherited_from = "openai",
				endpoint = "https://openrouter.ai/api/v1",
				api_key_name = "OPENROUTER_API_KEY",
				model = "openai/gpt-oss-120b:free",
				max_tokens = 4096,
			}

			opts.providers["Qwen3-Coder"] = {
				__inherited_from = "openai",
				endpoint = "https://openrouter.ai/api/v1",
				api_key_name = "OPENROUTER_API_KEY",
				model = "qwen/qwen3-coder",
				max_tokens = 4096,
				disable_tools = true,
			}

			opts.providers["Qwen3-Coder-Free"] = {
				__inherited_from = "openai",
				endpoint = "https://openrouter.ai/api/v1",
				api_key_name = "OPENROUTER_API_KEY",
				model = "qwen/qwen3-coder:free",
				max_tokens = 4096,
				disable_tools = true,
			}

			opts.providers["KAT-Coder-Pro"] = {
				__inherited_from = "openai",
				endpoint = "https://openrouter.ai/api/v1",
				api_key_name = "OPENROUTER_API_KEY",
				model = "kwaipilot/kat-coder-pro:free",
				max_tokens = 4096,
			}

			opts.providers["MiMo-v2-flash"] = {
				__inherited_from = "openai",
				endpoint = "https://openrouter.ai/api/v1",
				api_key_name = "OPENROUTER_API_KEY",
				model = "xiaomi/mimo-v2-flash:free",
				max_tokens = 4096,
			}

			opts.providers["Deepseek-R1t2"] = {
				__inherited_from = "openai",
				endpoint = "https://openrouter.ai/api/v1",
				api_key_name = "OPENROUTER_API_KEY",
				model = "tngtech/deepseek-r1t2-chimera:free",
				max_tokens = 4096,
			}

			opts.providers["Deepseek-R1-0528"] = {
				__inherited_from = "openai",
				endpoint = "https://openrouter.ai/api/v1",
				api_key_name = "OPENROUTER_API_KEY",
				model = "deepseek/deepseek-r1-0528:free",
				max_tokens = 4096,
			}

			opts.providers["Deepseek-R1t"] = {
				__inherited_from = "openai",
				endpoint = "https://openrouter.ai/api/v1",
				api_key_name = "OPENROUTER_API_KEY",
				model = "tngtech/deepseek-r1t-chimera:free",
				max_tokens = 4096,
			}

			opts.providers["GPT-OSS-20b"] = {
				__inherited_from = "openai",
				endpoint = "https://openrouter.ai/api/v1",
				api_key_name = "OPENROUTER_API_KEY",
				model = "openai/gpt-oss-20b:free",
				max_tokens = 4096,
			}

			opts.providers["Llama-3.3-70b"] = {
				__inherited_from = "openai",
				endpoint = "https://openrouter.ai/api/v1",
				api_key_name = "OPENROUTER_API_KEY",
				model = "meta-llama/llama-3.3-70b-instruct:free",
				max_tokens = 4096,
			}

			opts.providers["Devstral-2512"] = {
				__inherited_from = "openai",
				endpoint = "https://openrouter.ai/api/v1",
				api_key_name = "OPENROUTER_API_KEY",
				model = "mistralai/devstral-2512:free",
				max_tokens = 4096,
			}

			opts.providers["Kimi-k2"] = {
				__inherited_from = "openai",
				endpoint = "https://openrouter.ai/api/v1",
				api_key_name = "OPENROUTER_API_KEY",
				model = "moonshotai/kimi-k2:free",
				max_tokens = 4096,
			}

			opts.providers["Gemini-2.0-Flash"] = {
				__inherited_from = "openai",
				endpoint = "https://openrouter.ai/api/v1",
				api_key_name = "OPENROUTER_API_KEY",
				model = "google/gemini-2.0-flash-exp:free",
				max_tokens = 4096,
			}

			-- Set Default
			opts.provider = "MiMo-v2-flash"

			opts.behaviour = {
				auto_suggestions = false,
				auto_set_highlight_group = true,
				auto_set_keymaps = true,
				auto_apply_diff_after_generation = false,
				support_paste_from_clipboard = true,
			}

			return opts
		end,

		build = "make",

		dependencies = {
			"stevearc/dressing.nvim",
			"nvim-lua/plenary.nvim",
			"MunifTanjim/nui.nvim",
			{
				"HakonHarnes/img-clip.nvim",
				event = "VeryLazy",
				opts = {
					default = {
						embed_image_as_base64 = false,
						prompt_for_file_name = false,
						drag_and_drop = {
							insert_mode = true,
						},
					},
				},
			},
		},
	},
}
