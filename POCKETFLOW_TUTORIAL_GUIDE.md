# 🚀 PocketFlow Tutorial - AI-Powered Codebase Knowledge Generator

> **Transform any GitHub repository into beginner-friendly tutorials with AI!**

## 📖 What is PocketFlow Tutorial?

PocketFlow Tutorial is a revolutionary **100-line LLM framework** that automatically crawls GitHub repositories and builds comprehensive knowledge bases from code. It analyzes entire codebases to identify core abstractions and their interactions, then transforms complex code into beginner-friendly tutorials with clear visualizations.

### 🎯 **Key Capabilities**
- **🔍 Smart Code Analysis**: Identifies core abstractions and how they interact
- **📚 Auto-Tutorial Generation**: Creates beginner-friendly explanations from complex code
- **🎨 Visual Documentation**: Generates clear visualizations and diagrams
- **🌐 Multi-Language Support**: Generate tutorials in different languages
- **⚡ 100-Line Framework**: Minimal but powerful LLM framework architecture

## 🏆 **Project Achievements**

- 🎉 **Hacker News Front Page** (April 2025) with **900+ upvotes** 
- 🎊 **Online Service Live** at [code2tutorial.com](https://code2tutorial.com/)
- 📺 **YouTube Development Tutorial** available
- 📝 **Substack Tutorial** for detailed walkthrough

## 🌟 **Example AI-Generated Tutorials**

*All these tutorials are generated entirely by AI by crawling GitHub repositories!*

### 🤖 **AI & Machine Learning**
- **[AutoGen Core](https://github.com/microsoft/autogen)** - Build AI teams that talk, think, and solve problems together like coworkers!
- **[CrewAI](https://github.com/joaomdmoura/crewAI)** - Assemble a dream team of AI specialists to tackle impossible problems!
- **[DSPy](https://github.com/stanfordnlp/dspy)** - Build LLM apps like Lego blocks that optimize themselves!
- **[LangGraph](https://github.com/langchain-ai/langgraph)** - Design AI agents as flowcharts where each step remembers what happened before!

### 🌐 **Web Development**
- **[FastAPI](https://github.com/tiangolo/fastapi)** - Create APIs at lightning speed with automatic docs that clients will love!
- **[Flask](https://github.com/pallets/flask)** - Craft web apps with minimal code that scales from prototype to production!
- **[Browser Use](https://github.com/browser-use/browser-use)** - Let AI surf the web for you, clicking buttons and filling forms like a digital assistant!

### 🛠️ **Development Tools**
- **[Click](https://github.com/pallets/click)** - Turn Python functions into slick command-line tools with just a decorator!
- **[Requests](https://github.com/psf/requests)** - Talk to the internet in Python with code so simple it feels like cheating!
- **[Pydantic Core](https://github.com/pydantic/pydantic-core)** - Validate data at rocket speed with just Python type hints!

### 📊 **Data & Performance**
- **[NumPy Core](https://github.com/numpy/numpy)** - Master the engine behind data science that makes Python as fast as C!
- **[Celery](https://github.com/celery/celery)** - Supercharge your app with background tasks that run while you sleep!
- **[LevelDB](https://github.com/google/leveldb)** - Store data at warp speed with Google's engine that powers blockchains!

### 🕷️ **Data Extraction & AI Agents**
- **[Crawl4AI](https://github.com/unclecode/crawl4ai)** - Train your AI to extract exactly what matters from any website!
- **[SmolaAgents](https://github.com/huggingface/smolagents)** - Build tiny AI agents that punch way above their weight class!
- **[OpenManus](https://github.com/openai/manus)** - Build AI agents with digital brains that think, learn, and use tools just like humans do!

## 🚀 **Getting Started**

### **Prerequisites**
- Python 3.8+
- Git
- LLM API access (Gemini, Claude, GPT, etc.)

### **1. Clone the Repository**
```bash
git clone https://github.com/The-Pocket/PocketFlow-Tutorial-Codebase-Knowledge
cd PocketFlow-Tutorial-Codebase-Knowledge
```

### **2. Install Dependencies**
```bash
pip install -r requirements.txt
```

### **3. Configure LLM**
Set up your LLM in `utils/call_llm.py` by providing credentials.

**For Gemini Pro 2.5 (Default):**
```python
client = genai.Client(
    api_key=os.getenv("GEMINI_API_KEY", "your-api_key"),
)
```

**Recommended Models:**
- 🥇 **Claude 3.7 with thinking** (Best results)
- 🥈 **OpenAI O1** (Excellent reasoning)
- 🥉 **Gemini Pro 2.5** (Good performance)

### **4. Verify Setup**
```bash
python utils/call_llm.py
```

## 💻 **Usage Examples**

### **Analyze a GitHub Repository**
```bash
python main.py --repo https://github.com/username/repo \
               --include "*.py" "*.js" \
               --exclude "tests/*" \
               --max-size 50000
```

### **Analyze Local Directory**
```bash
python main.py --dir /path/to/your/codebase \
               --include "*.py" \
               --exclude "*test*"
```

### **Generate Tutorial in Different Language**
```bash
python main.py --repo https://github.com/username/repo \
               --language "Chinese"
```

### **Advanced Configuration**
```bash
python main.py --repo https://github.com/username/repo \
               --name "MyProject" \
               --output ./my-tutorials \
               --include "*.py" "*.js" "*.ts" \
               --exclude "tests/*" "docs/*" "node_modules/*" \
               --max-size 100000 \
               --language "Spanish" \
               --max-abstractions 15 \
               --no-cache
```

## ⚙️ **Command Line Options**

| Option | Description | Default |
|--------|-------------|---------|
| `--repo` / `--dir` | GitHub repo URL or local directory (required, mutually exclusive) | - |
| `-n, --name` | Project name | Derived from URL/directory |
| `-t, --token` | GitHub token | `GITHUB_TOKEN` env variable |
| `-o, --output` | Output directory | `./output` |
| `-i, --include` | Files to include (e.g., "*.py" "*.js") | All files |
| `-e, --exclude` | Files to exclude (e.g., "tests/*") | None |
| `-s, --max-size` | Maximum file size in bytes | 100KB |
| `--language` | Tutorial language | English |
| `--max-abstractions` | Maximum abstractions to identify | 10 |
| `--no-cache` | Disable LLM response caching | Caching enabled |

## 🐳 **Running with Docker**

```bash
# Build the Docker image
docker build -t pocketflow-tutorial .

# Run with GitHub repository
docker run -e GEMINI_API_KEY=your_key \
           -v $(pwd)/output:/app/output \
           pocketflow-tutorial \
           --repo https://github.com/username/repo

# Run with local directory
docker run -e GEMINI_API_KEY=your_key \
           -v /path/to/code:/app/input \
           -v $(pwd)/output:/app/output \
           pocketflow-tutorial \
           --dir /app/input
```

## 🎓 **How It Works**

### **1. Repository Crawling**
- Clones or reads the specified repository
- Filters files based on include/exclude patterns
- Respects file size limits for efficient processing

### **2. Code Analysis**
- Identifies core abstractions and design patterns
- Maps relationships between components
- Analyzes code structure and dependencies

### **3. Tutorial Generation**
- Uses advanced LLMs to create beginner-friendly explanations
- Generates visualizations and diagrams
- Structures content in a logical learning progression

### **4. Output Generation**
- Creates comprehensive markdown tutorials
- Includes code examples and explanations
- Provides visual diagrams and flowcharts

## 🔧 **Development with Agentic Coding**

This project was built using **Agentic Coding** - the fastest development paradigm where:
- 👨‍💻 **Humans Design**: Define requirements and architecture
- 🤖 **Agents Code**: AI handles implementation details
- ⚡ **Rapid Iteration**: Fast feedback and improvement cycles

The secret weapon is **PocketFlow** - a 100-line LLM framework that lets AI agents (like Cursor AI) build complex applications efficiently.

## 🌐 **Online Service**

Don't want to install locally? Try our **online version**:

🔗 **[code2tutorial.com](https://code2tutorial.com/)**

Simply paste a GitHub link - no installation needed!

## 📚 **Learning Resources**

- 📺 **[YouTube Development Tutorial](https://youtube.com/watch?v=your-video)** - Complete walkthrough
- 📝 **[Substack Tutorial](https://your-substack.com)** - Detailed written guide
- 💬 **[Hacker News Discussion](https://news.ycombinator.com/item?id=your-discussion)** - Community feedback
- 🗨️ **[GitHub Discussions](https://github.com/The-Pocket/PocketFlow-Tutorial-Codebase-Knowledge/discussions)** - Share your tutorials!

## 🤝 **Contributing**

We welcome contributions! Here's how you can help:

1. **🐛 Report Bugs**: Found an issue? Create a GitHub issue
2. **💡 Feature Requests**: Suggest new features or improvements
3. **📖 Tutorial Examples**: Share AI-generated tutorials in discussions
4. **🔧 Code Contributions**: Submit pull requests for improvements
5. **📚 Documentation**: Help improve documentation and guides

## 🎯 **Use Cases**

### **For Developers**
- 📖 **Learn New Codebases**: Quickly understand complex projects
- 🏫 **Create Documentation**: Auto-generate project documentation
- 🎓 **Educational Content**: Create tutorials for open-source projects

### **For Teams**
- 📋 **Onboarding**: Help new team members understand codebases
- 📚 **Knowledge Transfer**: Document institutional knowledge
- 🔄 **Code Reviews**: Better understand code structure and patterns

### **For Educators**
- 🎓 **Course Material**: Generate programming tutorials automatically
- 📝 **Code Examples**: Create real-world examples from popular projects
- 🌍 **Multi-Language**: Support for international students

## 🔮 **Future Roadmap**

- 🎨 **Enhanced Visualizations**: Interactive diagrams and flowcharts
- 🔗 **IDE Integration**: VS Code and other editor plugins
- 📱 **Mobile Support**: Generate tutorials optimized for mobile reading
- 🤖 **Custom Agents**: Specialized agents for different programming languages
- 🌐 **API Access**: RESTful API for programmatic access
- 📊 **Analytics**: Track tutorial effectiveness and user engagement

## 🛠️ **Technical Architecture**

```
PocketFlow Tutorial
├── 🕷️ Repository Crawler    # GitHub/Local file system access
├── 🧠 Code Analyzer         # AST parsing and pattern recognition  
├── 🤖 LLM Framework         # 100-line framework for AI processing
├── 📝 Tutorial Generator    # Content creation and structuring
└── 🎨 Output Formatter      # Markdown, diagrams, and visualizations
```

## 📄 **License**

This project is open source. Check the repository for specific license details.

## 🙏 **Acknowledgments**

- **The Pocket Team** - For creating this amazing framework
- **Open Source Community** - For providing countless examples and repositories
- **AI Research Community** - For advancing LLM capabilities
- **Contributors** - Everyone who helps improve this project

---

**✨ Ready to transform codebases into knowledge? Start exploring with PocketFlow Tutorial!**

*Built with ❤️ by The Pocket Team and the open source community* 